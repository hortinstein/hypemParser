//Modules
hypemParser = require('./parser');

//hypemParser();
hypemParser.hypeSearch("lil wayne carter");
///Module Includes
var redis = require('redis')
  , setupRedis = require('./setupRedis')
  , express = require('express')
 
var app = express();	
var server = app.listen(3000);
app.get("/", function(req, res) {
  res.redirect("/index.html");
});
app.configure(function() {
    app.use(express.static(__dirname + '/public'));
    app.use(app.router);
});


var io = require('socket.io').listen(server);
//Turns off the socket.io debug messages
io.set('log level', 1)

userCount = 0;


try { var config = require('./config.json');}
catch (err) {console.log("no config");};

var redisClient = setupRedis(config);
io.sockets.on('connection', function(client) {
    ++userCount;
    var sub = setupRedis(config);
    
    sub.subscribe("foundSong");
    sub.on("message", function(channel, message) {
        client.send(message);
    });
});