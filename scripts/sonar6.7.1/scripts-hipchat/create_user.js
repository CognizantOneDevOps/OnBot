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
sonarurl = sonarurl+"api/users/create?login="+userid+"&password="+userid+"&name="+userid;

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
	body = JSON.parse(body);
  if (error)
  {
	callback_user_create(null,"error",error);
  }
  else if(response.statusCode == 200)
  {
	  callback_user_create(null,"user created",null);
  }
  else
  {
	callback_user_create(body.errors[0].msg,null,"Couldn't create user. Please check logs.");
  }

  
});
}
module.exports = {
  create_user: function_call	// MAIN FUNCTION
  
}
