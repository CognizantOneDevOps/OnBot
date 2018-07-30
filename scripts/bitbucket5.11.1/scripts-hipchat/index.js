/*******************************************************************************
*Copyright 2018 Cognizant Technology Solutions
*  
*  Licensed under the Apache License, Version 2.0 (the "License"); you may not
*  use this file except in compliance with the License.  You may obtain a copy
*  of the License at
*  
*    http://www.apache.org/licenses/LICENSE-2.0
*  
*  Unless required by applicable law or agreed to in writing, software
*  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
*  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
*  License for the specific language governing permissions and limitations under
*  the License.
******************************************************************************/

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

module.exports.passData = function (msg){
    const data = {
      user: process.env.HUBOT_NAME,
      message: msg,
      type: "Chat",
	  timestamp: new Date()
	};
    logger.logs(data, (err) => {
      if (err) return robot.logger.error(err.message);
    });
    
};

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
