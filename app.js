//Modules
hypemParser = require('./parser');

//Constants
MILISECONDS = 1
SECONDS     = 1000 * MILISECONDS
MINUTES     = 60 * SECONDS
HOUR        = 60 * MINUTES

//loads database configs
try { var config = require('./config.json');} //loads the database configs
catch (err) {console.log("no config");};


//initializes crawler
var crawler = new hypemParser(config)


crawler.on('next', function (message) { //when the parser is ready for the next url to parse
    console.log(message);
    setTimeout(runParser,5000); //waits five seconds and calls the parser again
});

runParser = function  () {
    crawler.popular();
};

runParser(); //starts the parser loop