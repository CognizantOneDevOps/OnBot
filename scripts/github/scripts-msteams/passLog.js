/*Description:
passes hubot backend logs to elasticsearch

Configuration:
 HUBOT_NAME

COMMANDS:
None

Dependencies:
"fs": "0.0.1-security"
"elasticSearch": "^0.9.2"
"fs.notify": "0.0.4"
*/

const fs = require('fs');
const logger = require('./lib/logger');
const Notify = require('../node_modules/fs.notify');

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
notifications.on('change', function (file, event, path) {//to catch any change in hubot logs
	passHuLogs();//change in hubot.log caught, therefore sending data to elasticsearch
});

setTimeout(passHuLogs,1500);
};