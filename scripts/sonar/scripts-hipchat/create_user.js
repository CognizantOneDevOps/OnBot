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

//Load Dependencies
var request = require("request");

//Function to create user with parameters url,username,password,user_id
var function_call = function (sonarurl, username, password, userid, callback_user_create) {	
var sonar_url = sonarurl;
var username1 = username;
var password1 = password;
var user_id = userid;

sonar_url = sonar_url+"api/users/create?login="+user_id+"&password="+user_id+"&name="+user_id;

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
	body = JSON.parse(body);
  if (error)
  {
	  callback_user_create("Something went wrong","Something went wrong",null);
  }
  else if(response.statusCode == 200)
  {
	  callback_user_create(null,"",null);
  }
  else
  {
	  var str = JSON.stringify(body.errors);
	  callback_user_create(str,str,str);
  }

  
});
}
module.exports = {
  create_user: function_call	// MAIN FUNCTION
  
}
