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

var function_call = function (main_scalr_url, access_id, access_key, envid, farm_id, callback_farm_delete) {
var farm_name = farm_name;
var envid= envid;

var path = '/api/v1beta0/user/'+envid+'/farms/'+farm_id+'/';
var scalr_url = main_scalr_url + path;
var secret_key = access_key;
var access_id = access_id;

	    var timestamp = new Date().toISOString();
	var date = timestamp;

 
	
	var method = 'DELETE';
var params = '';


var toSign = method + '\n' + date + '\n' + path + '\n' + params + '\n';


var signature1 = CryptoJS.enc.Base64.stringify(CryptoJS.HmacSHA256(toSign, secret_key));
var sign = "V1-HMAC-SHA256 "+signature1;

process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
var options = { method: 'DELETE',
  url: scalr_url,
  headers: 
   { 
     'content-type': 'application/json',
     'x-scalr-signature': sign,
     'x-scalr-key-id': access_id,
     'x-scalr-date': date },
  json: true };

request(options, function (error, response, body) {

  if (error){
	  callback_farm_delete("Something went wrong","Something went wrong","Something went wrong");
  }
  else if(response.statusCode == 204)
  {

	  callback_farm_delete(null,"",null);

  }
  else
  {
	  callback_farm_delete("Something went wrong","Something went wrong","Something went wrong");
  }
	
  
});
}
module.exports = {
 farm_delete: function_call	// MAIN FUNCTION
}
