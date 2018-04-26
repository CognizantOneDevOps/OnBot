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

﻿process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
var Base64 = require('js-base64').Base64;
var request = require("request");

var function_call = function (urelease_url, username, password, app_name, callback_create_initiative) {
var user_pass = username + ':' + password;
var buf = Base64.encode(user_pass);
console.log(buf);
var options = { method: 'POST',
  url: urelease_url + '/initiatives/',
  headers:
   { 'content-type': 'application/json',
     authorization: 'Basic '+buf,
     accept: 'application/json' },
  body:
   { name: app_name,
     description: 'Creating initiative from bot with user '+ username,
	},
  json: true };

request(options, function (error, response, body) {

  if(!error && response.statusCode == 201){
	
	  var str = 'Intiative created with ID :: '+body.id+' and Name :: '+body.name+' date :: '+body.dateCreated;
	  callback_create_initiative("null",str,"null");
  }
   else{
	  callback_create_initiative(body,body,"Error");
  }

});
}


module.exports = {
  create_initiative: function_call	// MAIN FUNCTION
  
}
