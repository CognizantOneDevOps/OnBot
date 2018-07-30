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

//Load dependency
var request = require("request");

//Function to delete user with parameters url,username,password,user_id
var function_call = function (sonarurl, username, password, userid, callback_user_delete) {
sonarurl = sonarurl+"api/users/deactivate?login="+userid;

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
	callback_user_delete(error,"error","Something went wrong");
  }
  else if(response.statusCode == 200)
  {
	  callback_user_delete(null,"user deleted",null);
  }
  else
  {
	console.log(body)
	callback_user_delete(body.errors[0].msg,"error","Couldn't delete user. Please check logs.");
  }

  
});
}
module.exports = {
  delete_user: function_call	// MAIN FUNCTION
  
}
