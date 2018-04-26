/*******************************************************************************
*Copyright 2018 Cognizant Technology Solutions
* 
* Licensed under the Apache License, Version 2.0 (the "License"); you may not
* use this file except in compliance with the License.  You may obtain a copy
* of the License at
* 
*   http://www.apache.org/licenses/LICENSE-2.0
* 
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
* WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
* License for the specific language governing permissions and limitations under
* the License.
 ******************************************************************************/

var express = require('express');
var app=express();
var bodyparser=require('body-parser');
var fs = require('fs');
var http = require('http');
var https = require('https');
var config = require('./app/config/config.json');
var privateKey  = fs.readFileSync(config.PrivateKey_path);
var certificate = fs.readFileSync(config.Certificate_Path);
var credentials = {key: privateKey, cert: certificate};
app.use(bodyparser.json());
app.use(express.static(__dirname + "/public"));
require('./app/routes')(app);//For MongoDB
require('./app/deploybot')(app); //Deploy bot to remote machine 


require('./app/elasticApi')(app);//for elasticsearch api


var httpsServer = https.createServer(credentials, app);
httpsServer.listen(config.https_port,function(){console.log("Listening to https port: "+config.https_port)});
//httpServer.listen(config.http_port,function(){console.log("Listening to http port:"+config.http_port)});

