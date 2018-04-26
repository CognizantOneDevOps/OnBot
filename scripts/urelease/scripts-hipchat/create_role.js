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
var function_call = function (urelease_url, username, password, role_name, callback_create_role) {
var user_pass = username + ':' + password;
var buf = Base64.encode(user_pass);
console.log(buf);
var options = { method: 'POST',
  url: urelease_url + '/roles/',
  headers:
   { 'content-type': 'application/json',
     authorization: 'Basic '+buf,
     accept: 'application/json' },
  body:
{
  "name": role_name,
  "description": role_name,
  "actions": [
      ""
  ]
},
  json: true };


request(options, function (error, response, body) {
console.log(response.statusCode);
  if (!error && response.statusCode == 201){



var str = 'Role created with ID : '+body.id+' name : '+body.name+' version : '+body.version;

callback_create_role("null",str,"null");

  }
else
{
callback_create_role("Error","Error","Error");
}


});



}




module.exports = {
  create_role: function_call	// MAIN FUNCTION
  
}
