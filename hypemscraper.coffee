request = require("request")
cheerio = require("cheerio")
redis = require("redis")
moment = require('moment')

redis_client = ""

setup = (config) ->
  if config == undefined
    redis_client = redis.createClient()
  else
    redis_client = require("./setupRedis.js")(config)



MILISECONDS = 1
SECONDS = 1000 * MILISECONDS
MINUTES = 60 * SECONDS
HOUR = 60 * MINUTES

URL_REFRESH_INTERVAL = 10 * MINUTES;
SONG_REFRESH_INTERVAL = 1 * HOUR;

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
      redis_client.hmset(track.id, "download_url", data.url)
      #At this point we should add the track to the DB
      callback(track,data.url)
    else
      error("Error during request")


get_download_url = (id, callback, error) ->
  
  redis_client.exists id, (err, found) ->
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
      redis_client.hexists id, "download_url", (err, found)->
        if err or not found
          console.log("We've never fetched the download url (or error). Do it now!")

          redis_client.hgetall id, (err, track) ->
            helper_fetch_download_url(track, callback, error)
        else
          console.log("We've seen this song before so just serve the download url quickly!")
          redis_client.hgetall id, (err, track) ->
            callback(track, track.download_url )

    
search = (query, callback) ->
  query = encodeURIComponent(query)
  search_url = "http://hypem.com/search/#{query}"
  scrape(search_url, callback)

scrape_helper = (url, callback) ->
  data = 
    'ax' : 1
    'ts' : new Date().getTime

  options =
    url: url
    method: 'GET'
    qs: data
    jar: false

  request options , (error, response, body) ->
    if error?
      console.error "Error trying to perform the request to hypem.com"
      console.error error
      callback([])
      return

    unless response.statusCode is 200
      console.error "Non 200 status code when asking hypem.com for request. StatusCode - #{response.statusCode}"
      callback([])
      return 

    cookie = response.headers['set-cookie']
    $ = cheerio.load body
    page_data = JSON.parse $('#displayList-data').html()      
    valid_tracks = []

    unless page_data? #check for null
      console.error "Hypem.com did not return any displayList-data object!"
      callback([])
      return

    tracks = page_data.tracks

    for track in tracks
      continue if track.type is false
      track["title"] = track.song #pretty renaming
      track["cookie"] = cookie
      track["humanize_time"] = moment.humanizeDuration(SECONDS * track.time)

      valid_tracks.push(track)


    for track in valid_tracks
      redis_client.hmset(track.id,
        "id", track.id 
        "key", track.key,
        "artist", track.artist,
        "title", track.title,
        "time", track.time,
        "posturl", track.posturl,
        "cookie", track.cookie,
        "humanize_time", track.humanize_time
      )
      redis_client.pexpire track.id, SONG_REFRESH_INTERVAL

    caching_json = JSON.stringify(valid_tracks)

    redis_client.set url, caching_json, (err, res) ->
      redis_client.pexpire url, (URL_REFRESH_INTERVAL)
      callback(valid_tracks)

scrape = (url = "http://www.hypem.com/popular", callback ) ->

  redis_client.exists url, (err, found) ->
    if err or not found
      #We've not seen this URL ever before so just perform normal scraping!
      console.log("We've never seen #{url} before, or it expired. New scrape!")
      scrape_helper(url, callback)
    else
      redis_client.get url, (err, url_map_json ) ->

        url_map = JSON.parse(url_map_json)

        tracks = url_map
        console.log("We have a pretty recent copy of #{url}. So return that!")
        callback(tracks)


song_downloaded = (song_id) ->
  #Increase that songs download count by 1
  redis_client.hincrby song_id, "downloads", 1


module.exports.cache_client = redis_client
module.exports.setup = setup
module.exports.scrape  = scrape
module.exports.search  = search
module.exports.get_download_url = get_download_url
module.exports.song_downloaded = song_downloaded
