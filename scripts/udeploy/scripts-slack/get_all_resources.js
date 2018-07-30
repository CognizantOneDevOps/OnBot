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
var function_call = function (udeploy_url, username, password, callback_list_resource) {

var udeploy_url = udeploy_url;
var username = username;
var password = password;

var url = udeploy_url + '/cli/resource';
var options = { method: 'GET',
  url: url,
  auth: {
    user: username,
    password: password
  },
  qs: { active: 'true' }
 };
var active_components = '*ID*\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t*Resource Name*';
request(options, function (error, response, body) {
  if(error || response.statusCode != 200)
  {
          console.log("Error in getting resources: "+error);
		  callback_list_resource("Failed to fetch data. Check bot logs for error stacktrace","Error","Error");
  }
  else
  {

          body = JSON.parse(body);
          var length = body.length;
          for(i=0;i<length;i++)
          {



                  active_components = active_components + '\n' + body[i].id + '\t' + body[i].name;
          }
		  callback_list_resource("null",active_components,"null");
  }
        console.log(active_components);

});

}




module.exports = {
  get_all_resources: function_call	// MAIN FUNCTION
  
}
