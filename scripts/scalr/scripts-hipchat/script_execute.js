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

var request = require("request");
var CryptoJS = require("crypto-js");
var HashMap = require('hashmap');

var function_call = function (main_scalr_url, access_id, access_key, envid, script_id, server_id, callback_script_execute) {

var script_id = script_id;
var envid = envid;
var server_id = server_id;
var secret_key = access_key;
var access_id = access_id;

var path = '/api/v1beta0/user/'+envid+'/scripts/'+script_id+'/actions/execute/';
var scalr_url = main_scalr_url + path;
var timestamp = new Date().toISOString();
var date = timestamp;
var method = 'POST';
var params = '';


var toSign = method + '\n' + date + '\n' + path + '\n' + params + '\n' + '{"server":"'+server_id+'"}';
var signature1 = CryptoJS.enc.Base64.stringify(CryptoJS.HmacSHA256(toSign, secret_key));
var sign = "V1-HMAC-SHA256 "+signature1;

process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
var options = { method: 'POST',
  url: scalr_url,
  headers: 
   { 
     'content-type': 'application/json',
     'x-scalr-signature': sign,
     'x-scalr-key-id': access_id,
     'x-scalr-date': date },
  body: 
   { server: server_id
    },
  json: true };

request(options, function (error, response, body) {


  if (error){

	  callback_script_execute("Something went wrong","Something went wrong","Something went wrong");
  }
  else if(!(response.body.errors)) 
  {
          callback_script_execute(null,response.body.data.id,null);
	  
  }
  else {
       callback_script_execute(response.body.errors[0].message,null,null);
  }

});


}






module.exports = {
 script_execute: function_call	// MAIN FUNCTION
  
}
