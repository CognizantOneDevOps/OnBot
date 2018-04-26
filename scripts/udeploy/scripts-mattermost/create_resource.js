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
var function_call = function (resource_name, udeploy_url, username, password, callback_create_resource) {



var request = require('request');
var udeploy_url = udeploy_url;
var username = username;
var password = password;
var resource_name = resource_name;
var dataString = '{"name":"'+resource_name+'","description":"creating resource from bot"}';
var url = udeploy_url + '/cli/resource/create';
var options = {
    url: url,
    method: 'PUT',
        body: dataString,
    auth: {
        'user': username,
        'pass': password
    }
};

function callback(error, response, body) {
    if (!error && response.statusCode == 200) {

		body = JSON.parse(body);
        var id = 'Resource create dwith ID : '+body.id;

		callback_create_resource("null",id,"null");
    }
	else
	{

		callback_create_resource("Failed to create resource. Check bot logs for error stacktrace","Error","Error");
	}
}

request(options, callback);


}




module.exports = {
  create_resource: function_call	// MAIN FUNCTION
  
}
