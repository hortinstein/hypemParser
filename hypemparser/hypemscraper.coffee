request = require("request")
cheerio = require("cheerio")
redis = require("redis")

redis_client = redis.createClient()


MILISECONDS = 1
SECONDS = 1000 * MILISECONDS
MINUTES = 60 * SECONDS
HOUR = 60 * MINUTES

intervalId = null

start = () ->
  unless intervalId? 
    scrape()
    intervalId = setInterval scrape, 1 * HOUR 

stop = () ->
  if intervalId?
    clearInterval(intervalId)
    intervalId = null


scrape = (url = "http://www.hypem.com/popular" ) ->
  data = 
    'ax' : 1
    'ts' : new Date().getTime

  options =
    url: url
    method: 'GET'
    qs: data

  request options , (error, response, body) ->
      unless error? and response.statusCode is 200
        $ = cheerio.load body
        page_data = JSON.parse $('#displayList-data').html()
        tracks = page_data.tracks
        cookie = response.headers['set-cookie']

        tracks.forEach (track, index, tracks) ->
          #Songs which have the track.type to false are no longer available for streaming
          return if track.type is false

          id = track.id
          key = track.key
          track_data_url = "http://hypem.com/serve/source/#{id}/#{key}"

          headers = 
            cookie: cookie

          options = 
            url : track_data_url
            method: 'GET'
            json : true
            headers : headers

          request options , (error, response, data) ->
            unless error? and response.statusCode is 200
              track.url = data.url

              redis_client.publish "hypemscraper", JSON.stringify(track)


module.exports.start  = start
module.exports.stop  = stop
module.exports.scrape  = scrape

