request = require("request")
cheerio = require("cheerio")
redis = require("redis")
require('coffee-script')
client = redis.createClient()

client.on "error", (error) ->
  console.log("Redis Scraper Error: #{error}" )

POPULAR = "http://www.hypem.com/popular"
LATEST = "http://hypem.com/latest/"

MILISECONDS = 1
SECONDS = 1000 * MILISECONDS
MINUTES = 60 * SECONDS
HOUR = 60 * MINUTES

start = () ->
  unless intervalId? 
    scrape POPULAR, (tracks) ->
      console.log("popular scrape complete")
    scrape LATEST, (tracks) ->
      console.log("latest scrape complete") 
    intervalId = setInterval scrape, 2 * MINUTES 

stop = () ->
  if intervalId?
    clearInterval(intervalId)
    intervalId = null

helper_fetch_download_url = (track, callback, error)->
  id = track.id
  key = track.key
  track_data_url = "http://hypem.com/serve/source/#{id}/#{key}"

  headers = 
    cookie: track.cookie

  options = 
    url : track_data_url
    method: 'GET'
    json : true
    headers : headers

  console.log(track)
  console.log("Performing request to : #{track_data_url}")

  request options , (error, response, data) ->
    unless error? and response.statusCode is 200
      client.hmset(track.id, "download_url", data.url)
      #At this point we should add the track to the DB
      callback(data.url)
    else
      error("Error during request")


get_download_url = (id, callback, error) ->
  
  client.exists id, (err, found) ->
    if err or not found
      console.log("Must scrape song page first")
      track_url = "http://hypem.com/track/#{id}"

      scrape track_url, (tracks) ->
        if tracks.length is 0
          error("Did not find any tracks at #{track_url}")
          return
        helper_fetch_download_url(tracks[0], callback, error)

    else
      console.log("We have data in redis for song! No need to scrape")
      client.hexists id, "download_url", (err, found)->
        if err or not found
          console.log("We've never fetched the download url (or error). Do it now!")

          client.hgetall id, (err, track) ->
            helper_fetch_download_url(track, callback, error)
        else
          console.log("We've seen this song before so just serve the download url quickly!")
          client.hget id, "download_url" , (err, download_url) ->
            callback(download_url)

    
search = (query, callback) ->
  query = encodeURIComponent(query)
  search_url = "http://hypem.com/search/#{query}"
  scrape(search_url, callback)

scrape = (url = POPULAR, callback ) ->
  data = 
    'ax' : 1
    'ts' : new Date().getTime

  options =
    url: url
    method: 'GET'
    qs: data
    jar: false

  request options , (error, response, body) ->
    unless error? and response.statusCode is 200
      cookie = response.headers['set-cookie']
      $ = cheerio.load body
      page_data = JSON.parse $('#displayList-data').html()
      tracks = page_data.tracks

      valid_tracks = []
      for track in tracks
        continue if track.type is false
        track["title"] = track.song #pretty renaming
        track["cookie"] = cookie
        valid_tracks.push(track)


      for track in valid_tracks
        client.hmset(track.id,
          "id", track.id 
          "key", track.key,
          "artist", track.artist,
          "title", track.title,
          "cookie", track.cookie
        )
        #caching code to store tracks 
        if url == POPULAR
          client.sadd("popular",track.id)
        if url == LATEST
          client.sadd("latest",track.id)
      client.expire("popular",120) #expires entries every two min
      client.expire("popular",120) #expires entries every two min
      callback(valid_tracks)
    else
      console.error "Error trying to perform the request to hypem.com"
      callback([])

popular = (callback) ->
  track_list = []
  createClient.smembers "popular" (err,track_ids) ->
    if err
      return []
    else 
      for id in track_ids
        client.hgetall id, (err,track_data)->  
          if err
            continue
          else
            track_list.push(track_data)
      callback(track_list)


latest = (callback) ->
  track_list = []
  createClient.smembers "latest" (err,track_ids) ->
    if err
      return []
    else 
      for id in track_ids
        client.hgetall id, (err,track_data)->  
          if err
            continue
          else
            track_list.push(track_data)
      callback(track_list)

module.exports.latest  = latest
module.exports.popular = popular
module.exports.start   = start
module.exports.scrape  = scrape
module.exports.search  = search
module.exports.get_download_url = get_download_url