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
var function_call = function (user_name, udeploy_url, username, password, callback_delete_user) {



var udeploy_url = udeploy_url;
var create_user_name = user_name;
var username = username;
var password = password;
var component_name = component_name;

var url = udeploy_url + '/cli/user/delete?user='+create_user_name;
var options = {
    url: url,
    method: 'PUT',
    auth: {
        'user': username,
        'pass': password
    }
};




function callback(error, response, body) {
    if (!error && response.statusCode == 204) {
		var id = 'User deleted with Name :: '+create_user_name;

		callback_delete_user("null",id,"null");
    }
	else
	{
		callback_delete_user("Failed to delete user. Check bot logs for error stacktrace","Error","Error");
	}
}

request(options, callback);



}




module.exports = {
  delete_user: function_call	// MAIN FUNCTION
  
}



