var redis = require('redis');

function redisInit(config){
	var redisClient = redis.createClient(config.redis_port,config.redis_host); // creates the client to save the submissions to the database
	var dbAuth = function(){ 
	  redisClient.auth(config.redis_pass, function() {
	    //console.log("Connected!");
	  });
	};
	redisClient.addListener('connected', dbAuth); 
	redisClient.addListener('connected', dbAuth); 
	redisClient.addListener('reconnected', dbAuth );
	redisClient.on('disconnect', function  () {
	  console.log('RedisClient: Disconnected');
	});
	redisClient.on('error', function (err) { 
	  console.log("RedisClient: Error:" + err);
	  redisClient = redis.createClient(config.redis_port,config.redis_host);
	  dbAuth();
	});
	dbAuth();
	return redisClient;
}

module.exports  = redisInit;






