request = require("request")
cheerio = require("cheerio")
redis = require("redis")

redis_client = ""

set_DB_clients = (config) ->
  if config == undefined
    redis_client = redis.createClient()
  else
    redis_client = require("./setupRedis.js").redisInit(config)
  #couch_client = require("./configCouch.js") 

MILISECONDS = 1
SECONDS = 1000 * MILISECONDS
MINUTES = 60 * SECONDS
HOUR = 60 * MINUTES

REFRESH_INTERVAL = 5 * MINUTES;

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
      callback(data.url)
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
          redis_client.hget id, "download_url" , (err, download_url) ->
            callback(download_url)

    
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
        redis_client.hmset(track.id,
          "id", track.id 
          "key", track.key,
          "artist", track.artist,
          "title", track.title,
          "cookie", track.cookie
        )

      caching = 
        timestamp : new Date().getTime()
        tracks : valid_tracks

      caching_json = JSON.stringify(caching)

      redis_client.set url, caching_json, (err, res) ->
        callback(valid_tracks)

    else
      console.error "Error trying to perform the request to hypem.com"
      callback([])

scrape = (url = "http://www.hypem.com/popular", callback ) ->

  redis_client.exists url, (err, found) ->
    if err or not found
      #We've not seen this URL ever before so just perform normal scraping!
      console.log("We've never seen #{url} before. New scrape!")
      scrape_helper(url, callback)
    else
      #We've seen this URL before so lets grab it and check timestamp!
      redis_client.get url, (err, url_map_json ) ->

        url_map = JSON.parse(url_map_json)

        timestamp = url_map.timestamp;
        current_time = new Date().getTime()
        time_diff = current_time - timestamp

        tracks = url_map.tracks

        if time_diff < ( 5 * MINUTES )
          #It's been less than the refresh rate. Return the songs!
          console.log("We have a pretty recent copy of #{url}. So return that!")
          callback(tracks)
        else
          #It's been too long. Let's rescrape!
          console.log("Our copy of #{url} is old. New scrape!")
          scrape_helper(url, callback)

module.exports.set_DB_clients = set_DB_clients
module.exports.scrape  = scrape
module.exports.search  = search
module.exports.get_download_url = get_download_url