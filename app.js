try { var config = require('./config.json');} //loads the database configs
catch (err) {console.log("no config");};

hypemParser = require('./parser');

var crawler = new hypemParser();//,nano);

crawler.on('next', function (message) { //when the parser is ready for the next url to parse
    console.log(message);
    setTimeout(runParser,5000); //waits five seconds and calls the parser again
});

runParser = function  () {
    crawler.popular();
};

runParser(); //starts the parser loop