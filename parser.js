var http = require('http');
var events = require('events');
var redis = require('redis');
var request = require('request'); //module used to request the html from hypem
var jsdom = require("jsdom"); //DOM parser
var cheerio = require('cheerio');
var stats = require('measured').createCollection();
var redisInit = require('./setupRedis');
MILISECONDS = 1
SECONDS     = 1000 * MILISECONDS
MINUTES     = 60 * SECONDS
HOUR        = 60 * MINUTES

//loads database configs
try { var config = require('./config.json');} //loads the database configs
catch (err) {console.log("no config");};



function hypemParser(){
    this.emitForNext = function  (message) {
        this.emit("next", message); //this allows the parser to signal when it is complete parsing the page
    };
    
    //getHypeURL

    this.getHypeURL = function (url, callback) { 
        self = this; 
        data  = {
            "ax": 1,
            "ts": Date().getTime
        }
        request({url:url, method:'GET',qs:data}, function (error, response, body) {  
            if (!error){
                callback(body,response.headers['set-cookie']); //call the callback function
                self.emitForNext();
            } else{
                console.log(error);
                self.emitForNext("error pulling json:" + error);
            }
        });
    };
}

//Lets reddit parser user the EventEmitter methods
hypemParser.prototype = new process.EventEmitter();



hypemParser.prototype.getTracksJSONFromHtml = function(body,cookie) {    
    $ = cheerio.load(body);
    page_data = JSON.parse( $('#displayList-data').html() );

    tracks = page_data.tracks;
    for (var track in tracks){
        songData = tracks[track];
        var trackDataURL = "http://hypem.com/serve/source/#{id}/#{key}";
        var id = songData.id;
        var key = songData.key;
        var headers = {
            cookie: cookie
        }
        request({url:trackDataURL, method:'GET',json:true,headers:headers}, function (error, response, data) {  
            if (!error){
                songData.url = data.url;
                console.log(data.url);
                //callback(null,songData); //call the callback function
            } else{
                
            }
        });
    }

}





    //                 request options , (error, response, data) ->
    //                     unless error? and response.statusCode is 200
    //                         track.url = data.url
    //                         #At this point we should add the track to the DB
    //                         console.log track   


//sits on the new json of Gone wild and pulls down the posts
hypemParser.prototype.popular = function() {
    this.getHypeURL("http://www.hypem.com/popular",this.getTracksJSONFromHtml);
};



module.exports  = hypemParser;
