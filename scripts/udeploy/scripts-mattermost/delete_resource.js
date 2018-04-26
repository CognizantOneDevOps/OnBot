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
var function_call = function (resource_name, udeploy_url, username, password, callback_delete_resource) {




var udeploy_url = udeploy_url;
var username = username;
var password = password;
var resource_name = resource_name;

var url = udeploy_url + '/cli/resource';
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

		  callback_delete_resource("Failed to delete the resource. Check bot logs for error stacktrace","Error","Error");
  }
  else
  {        body = JSON.parse(body);
          var length = body.length;
          for(i=0;i<length;i++)
          {
                                if(resource_name == body[i].name)
                                {
                                        var url = udeploy_url + '/cli/resource/deleteResource?resource='+body[i].id;
                                        var options_delete = {
                                                                url: url,
                                                                method: 'DELETE',
                                                                auth: {
                                                                        'user': username,
                                                                        'pass': password
                                                                                }
                                                                };

                                        function callback_delete(error, response, body) {
                                                if (!error && response.statusCode == 204) {

																var str = 'Resource deleted with name :: '+resource_name;
																callback_delete_resource("null",str,"null");
                                                        }
														else
														{
															callback_delete_resource(error,"Error","Error");
														}
                                                        }

                                                        request(options_delete, callback_delete);
                                                        break;
                                }
          }
  }

});



}




module.exports = {
  delete_resource: function_call	// MAIN FUNCTION
  
}
