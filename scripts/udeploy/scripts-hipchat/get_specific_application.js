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
var function_call = function (app_name, udeploy_url, username, password, callback_get_application) {



var udeploy_url = udeploy_url;
var username = username;
var password = password;
var app_name = app_name;
var url = udeploy_url + '/cli/application/info?application=' + app_name;
var options = { method: 'GET',
  url: url,
  auth: {
    user: username,
    password: password
  },
  qs: { active: 'true' }
 };
var active_components = '';
request(options, function (error, response, body) {
  if(error || response.statusCode != 200)
  {
		  callback_get_application("Failed to fetch application data. Check bot logs for error stacktrace","Error","Error");
  }
  else
  {

          body = JSON.parse(body);


                  active_components = active_components + '\nID : ' + body.id + '\tName : ' + body.name + '\tDescription : ' +body.description + '\tEpochTime : ' + body.created + '\tSecurityID : ' + body.securityResourceId + '\tUser : ' +body.user + '\tComponentCount' + body.componentCount;
				  callback_get_application("null",active_components,"null");
  }


});


}




module.exports = {
  get_specific_application: function_call	// MAIN FUNCTION
  
}
