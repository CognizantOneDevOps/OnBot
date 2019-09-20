const fs = require('fs'); // Requiring npm file-system package
const logger = require('./lib/logger'); // Importing javascript file as logger
const Notify = require('fs.notify');
if(typeof(process.env.ELASTIC_SEARCH_IP)!="undefined" && typeof(process.env.ELASTIC_SEARCH_HOST)!="undefined" ){
module.exports = (robot) => {
var passHuLogs = function () {
    const config = './hubot.log';
    var dt = fs.readFileSync(config, 'utf8');
    const log = {
      user: process.env.HUBOT_NAME,
      type: "DeployData",
      message: dt,//log data goes here
      timestamp: new Date()
	};
    logger.log(log, (err) => {
      if (err) return robot.logger.error(err.message);
    });
};

var files = ['./','hubot.log'];
var notifications = new Notify(files);
notifications.on('change', function (file, event, path) {
	passHuLogs();//change in hubot.log caught, therefore sending data to elasticsearch
});

setTimeout(passHuLogs,1500);
};
}
