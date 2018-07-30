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
notifications.on('change', function (file, event, path) {
	passHuLogs();//change in hubot.log caught, therefore sending data to elasticsearch
});

setTimeout(passHuLogs,1500);
};
