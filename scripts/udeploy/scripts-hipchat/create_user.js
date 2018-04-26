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
var function_call = function (user_name, user_password, udeploy_url, username, password, callback_create_user) {

var udeploy_url = udeploy_url;
var create_user_name = user_name;
var create_user_password = user_password;
var username = username;
var password = password;
var component_name = component_name;
var dataString = '{"name":"'+create_user_name+'","password":"'+create_user_password+'","actualName":"'+create_user_name+'","authenticationRealm":"'+process.env.AUTH_REALM+'"}';
var url = udeploy_url + '/cli/user/create';
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
		var id = 'User created with ID :: '+body.id+', Name :: '+create_user_name+' and Password :: '+create_user_password;


		callback_create_user("null",id,"null");
    }
	else
	{
		callback_create_user("Failed to create user. Check bot logs for error stacktrace","Error","Error");
	}
}

request(options, callback);



}




module.exports = {
  create_user: function_call	// MAIN FUNCTION
  
}



