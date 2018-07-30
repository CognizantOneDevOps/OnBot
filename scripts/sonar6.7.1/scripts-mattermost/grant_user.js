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

//Load dependencies
var request = require("request");

//Function to grant permission to user with parameters url,username,password,user_id,permission,project
var function_call = function (sonarurl, username, password, permission, project_id, userid, callback_grant_user) {
sonarurl = sonarurl+"api/permissions/add_user?permission="+permission+"&login="+userid+"&projectKey="+project_id;

var options = { 
auth: {
        'user': username,
        'pass': password
    },
method: 'POST',
  url: sonarurl,
  headers: 
   {  } };

request(options, function (error, response, body) {
  if (error)
  {
	  callback_grant_user(error,"error",null);
  }
  else if(response.statusCode == '204')
  {
	  
	  callback_grant_user(null,"",null);
  }
  else
  {
	  body = JSON.parse(body);
	  console.log(body)
	  callback_grant_user(body.errors[0].msg,"error","Error occured! Please check logs.");
  }
});
}
module.exports = {
  grant_user: function_call	// MAIN FUNCTION
  
}
