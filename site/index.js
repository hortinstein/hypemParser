require('coffee-script')

var scraper = require('hypemparser')

var redis  = require("redis");

redis_client = redis.createClient()

redis_client.subscribe("hypemscraper")


redis_client.on("message", function(channel, message) {
console.log(message)
});


scraper.scrape();


