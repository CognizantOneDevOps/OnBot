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

//Load Dependencies
var request = require("request");

//Function to revoke permission from user with parameters url,username,password,user_id,permission,project
var function_call = function (sonarurl, username, password, perm, projid, userid, callback_revoke_user) {	
var sonar_url = sonarurl;
var username1 = username;
var password1 = password;
var user_id = userid;
var permission = perm;
var project_id = projid;

sonar_url = sonar_url+"api/permissions/remove_user?permission="+permission+"&login="+user_id+"&projectKey="+project_id;

var options = { 
auth: {
        'user': username1,
        'pass': password1
    },
method: 'POST',
  url: sonar_url,
  headers: 
   {  } };

request(options, function (error, response, body) {

  if (error)
  {
	  callback_revoke_user("Something went wrong","Something went wrong",null);
  }
  else if(response.statusCode == 204)
  {
	  callback_revoke_user(null,"",null);
  }
  else
  {
	  body = JSON.parse(body);
	  var str = JSON.stringify(body.errors);
	  callback_revoke_user(str,str,str);
  }

  
});
}
module.exports = {
  revoke_user: function_call	// MAIN FUNCTION
  
}
