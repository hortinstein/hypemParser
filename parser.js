var http = require('http');
var events = require('events');
var redis = require('redis');
var request = require('request'); //module used to request the html from hypem
var jsdom = require("jsdom"); //DOM parser

var stats = require('measured').createCollection();

//small reoccuring service that dumps out requests per second
setInterval(function() {
    console.log(stats.toJSON().requestsPerSecond.mean + " hypem requests per second");
}, 5000); //outputs the metrics

function hypemParser(){
    this.emitForNext = function  (message) {
        this.emit("next", message); //this allows the parser to signal when it is complete parsing the page
    };
    
    //getHypeURL

    this.getHypeURL = function (url, callback) { 
        self = this; 
        stats.meter('requestsPerSecond').mark();
        request({url:url, html:true}, function (error, response, body) {  
            if (!error){
                callback(body); //call the callback function
            } else{
                console.log(error);
                self.emitForNext("error pulling json:" + error);
            }
        });
    };
}

//Lets reddit parser user the EventEmitter methods
hypemParser.prototype = new process.EventEmitter();

hypemParser.prototype.getSongsFromHtml = function(html) {
    //console.log(html);
    jsdom.env(
        html,
        ["http://code.jquery.com/jquery.js"],
        function(errors, window) {
            var $ = window.jQuery;
            console.log(html.indexOf('id="displayList-data"'));
            console.log($('displayList-data').text());
           
        //console.log("json:", window.$("displayList-data").text());
        }
    );
    
};
//sits on the new json of Gone wild and pulls down the posts
hypemParser.prototype.popular = function() {
    this.getHypeURL('http://www.hypem.com/popular',this.getSongsFromHtml);
};



module.exports  = hypemParser;
