/*
Description:
 Logs chats to Elasticsearch
Configuration:
 HUBOT_ELASTICSEARCH_LOGGER_HOST - The Elasticsearch host
 HUBOT_ELASTICSEARCH_LOGGER_PORT - The Elasticsearch port
 HUBOT_ELASTICSEARCH_LOGGER_INDEX - The Elasticsearch index to use for storing chats
*/

'use strict';

const logger = require('./lib/logger');
const logger_wall = require('./lib/logger_wall');

module.exports = (robot) => {
  robot.hear(/.+/, (res) => {
    const msg = res.message;
    
    // don't log private messages
    if (!msg.room) return;

    const data = {
      user: msg.user.name,
      message: msg.text,//data is set here
      room: msg.room,
      type: "Chat",
      timestamp: new Date()
    };

    logger.logs(data, (err) => {
      if (err) return robot.logger.error(err.message);
    });
  });

module.exports.wallData = function (botname,msg,actionmsg,statusmsg){
    const data = {
      user: process.env.HUBOT_NAME,
      command: msg,
      message: actionmsg,
      buildstatus: statusmsg,
      timestamp: new Date()
    };
    logger_wall.log(data, (err) => {
      if (err) return robot.logger.error(err.message);
    });
    
};
};