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

var request = require("request");
var function_call = function (udeploy_url, username, password, callback_create_token) {
var request = require('request');
var udeploy_url = udeploy_url;
var username = username;
var password = password;
var url = udeploy_url + '/cli/teamsecurity/tokens?user='+username+'&expireDate=12-31-2020-12:00';
var options = {
    url: url,
    method: 'PUT',
    auth: {
        'user': username,
        'pass': password
    }
};

function callback(error, response, body) {
    if (!error && response.statusCode == 200) {

		body = JSON.parse(body);
        var id = 'Token : '+body.token+' and it will be expired on 12-31-2020-12:00';
		callback_create_token("null",id,"null");
    }
	else
	{
		callback_create_token("Failed to create token. Check bot logs for error stacktrace","Error","Error");
	}
}

request(options, callback);


}

module.exports = {
  create_token: function_call	// MAIN FUNCTION
  
}

var request = require('request');
var options = {
    url: udeploy_url + '/cli/teamsecurity/token?user='+username+'&expireDate=Never',
    method: 'PUT',
    auth: {
        'user': username,
        'pass': password
    }
};

function callback(error, response, body) {
    if (!error && response.statusCode == 200) {
        console.log(body);
    }
}

request(options, callback);
