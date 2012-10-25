var http = require('http');
var events = require('events');
var redis = require('redis');
var request = require('request'); //module used to request the html from hypem
var jsdom = require("jsdom"); //DOM parser
var cheerio = require('cheerio');
var stats = require('measured').createCollection();
var redisInit = require('./setupRedis');

intervalID = null;

MILISECONDS = 1
SECONDS     = 1000 * MILISECONDS
MINUTES     = 60 * SECONDS
HOUR        = 60 * MINUTES

//loads database configs
try { var config = require('./config.json');} //loads the database configs
catch (err) {console.log("no config");};

redisClient = redisInit(config);

function start() {
    scrape();
    if (!intervalID){
        intervalID = setInterval(scrape, 30 * MINUTES);    
    }
    
};
function stop() {
    if (intervalID){
        clearInterval(intervalId);
        intervalID = null;
    }
};
function scrape(){
    getHypeURL("http://www.hypem.com/popular");
}


function getHypeURL(url) {

    self = this; 
    data  = {
        "ax": 1,
        "ts": Date().getTime
    }
    request({url:url, method:'GET',qs:data}, function (error, response, body) {  
        if (!error){
            getTracksJSONFromHtml(body);
        } else{
            console.log(error);
        }
    });
};


function getTracksJSONFromHtml (body,cookie) {    
    $ = cheerio.load(body);
    page_data = JSON.parse( $('#displayList-data').html() );

    tracks = page_data.tracks;
    for (var track in tracks){
        songData = tracks[track];
        getSongURL(songData,cookie)
    }

}

function getSongURL(songData,cookie){
    var id = songData.id;
    var key = songData.key;""
    var trackDataURL = "http://hypem.com/serve/source/"+id+"/"+key;
    var headers = {
        cookie: cookie
    }
    request({url:trackDataURL, method:'GET',json:true,headers:headers}, function (error, response, data) {  
        if (!error){
            songData.url = data.url;
            console.log(songData);
            redisClient.HMSET("hypemPopular::"+songData.id, 
                            {
                                "id": toString(songData.id),
                                "postid": toString(songData.postid),
                                "postur": toString(songData.posturl),
                                "key": toString(songData.key),
                                "artist": toString(songData.artist),
                                "title": toString(songData.title),
                                "song": toString(songData.song),
                                "url": toString(songData.url),                               
                            });
            redisClient.publish("foundSong", songData.artist + songData.song)
        } else{
            songData.url = data.null;
        }
    });
}


module.exports  = start;


