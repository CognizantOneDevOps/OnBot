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

var function_call = function (main_scalr_url, access_id, access_key, envid, farm_name, role_name, os_name, callback_role_create) {
var farm_name = farm_name;
var envid= envid;
var alias = role_name;
var path = '/api/v1beta0/user/'+envid+'/farms/'+farm_name+'/farm-roles/';
var scalr_url = main_scalr_url + path;
var secret_key = access_key;
var access_id = access_id;

var timestamp = new Date().toISOString();
var date = timestamp;
var os_id = '';
var instance_os_type = '';

var cloud_platform=process.env.SCALR_CLOUD_PLATFORM;
var cloud_location=process.env.SCALR_CLOUD_LOCATION;
var network_id=process.env.SCALR_NETWORK_ID;
var subnet_id=process.env.SCALR_SUBNET_ID;
var security_id=process.env.SCALR_SECURITY_GROUP_ID;



if(os_name == 'ubuntu')
{
	os_id = 38241;
	instance_os_type = 't1.micro';
}
else if(os_name == 'windows')
{
	os_id = 59970;
	instance_os_type = 't2.micro';
}
else
{
	os_id = 38241;
	instance_os_type = 't1.micro';
}
	
var method = 'POST';
var params = '';


var toSign = method + '\n' + date + '\n' + path + '\n' + params + '\n' + '{"alias":"'+alias+'","cloudPlatform":"'+cloud_platform+'","cloudLocation":"'+cloud_location+'","instanceType":"'+instance_os_type+'","networking":{"networks":[{"id":"'+network_id+'"}],"subnets":[{"id":"'+subnet_id+'"}]},"role":'+os_id+',"scaling":{"enabled":false,"maxInstances":1,"minInstances":1},"security":{"securityGroups":[{"id":"'+security_id+'"}]}}';


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
   { alias: alias,
     cloudPlatform: cloud_platform,
	 
     cloudLocation: cloud_location,
     instanceType: instance_os_type,
	 networking:
	 {
	 networks:
	 [{
		 id: network_id
	 }],
	 subnets:
	 [{
		 id: subnet_id
	 }]
	 },
     role: os_id,
     scaling:
     {
		 enabled: false,
		 maxInstances: 1,
		 minInstances: 1
	 },
	 security:
	 {
	 securityGroups:
	 [{
		 id: security_id
	 }]
	 }
	 },
  json: true };

request(options, function (error, response, body) {
  if (error){
	  callback_role_create("Something went wrong","Something went wrong","Something went wrong");
  }
  else if(response.statusCode == 201)
  {
	  callback_role_create(null,response.body.data.id,null);  
  }
  else
  {
	  callback_role_create("Something went wrong","Something went wrong","Something went wrong");
	  
  }

});


}






module.exports = {
 role_create: function_call	// MAIN FUNCTION
  
}
