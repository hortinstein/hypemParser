var http = require('http');
var events = require('events');
var redis = require('redis');
var request = require('request'); //module used to request the html from hypem
var cheerio = require('cheerio');
var stats = require('measured').createCollection();
var redisInit = require('./setupRedis');

intervalID = null;

MILISECONDS = 1
SECONDS     = 1000 * MILISECONDS
MINUTES     = 60 * SECONDS
HOUR        = 60 * MINUTES

var hypemParser = [];    
module.exports = hypemParser;
//loads database configs
try { var config = require('./config.json');} //loads the database configs
catch (err) {console.log("no config");};

redisClient = redisInit(config);

hypemParser.start = function() {
    scrape();
    if (!intervalID){
        intervalID = setInterval(scrape, 30 * MINUTES);    
    }
    
};
hypemParser.stop = function() {
    if (intervalID){
        clearInterval(intervalId);
        intervalID = null;
    }
};
hypemParser.scrape = function(){
    hypemParser.getHypeURL("http://www.hypem.com/popular");
}


hypemParser.getHypeURL = function(url) {
    self = this; 
    data  = {
        "ax": 1,
        "ts": Date().getTime
    }
    request({url:url, method:'GET',qs:data}, function (error, response, body) {  
        if (!error){
            hypemParser.getTracksJSONFromHtml(body);
        } else{
            console.log(error);
        }
    });
};

hypemParser.getTracksJSONFromHtml = function (body,cookie) {    
    $ = cheerio.load(body);
    page_data = JSON.parse( $('#displayList-data').html() );

    tracks = page_data.tracks;
    for (var track in tracks){
        songData = tracks[track];
        hypemParser.getSongURL(songData,cookie)
    }
}

hypemParser.hypeSearch = function(query){
    query.replace(' ','%20');
    hypemParser.getHypeURL("http://www.hypem.com/search/"+query+"/");
}

hypemParser.getSongURL = function(songData,cookie){
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




