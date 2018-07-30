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

//Function to list user with parameters url,username,password
var function_call = function (sonarurl, username, password, projectid, callback_list_user) {

sonarurl = sonarurl+"api/users/search";

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
console.log(body);
console.log(error);
	
  if (error)
  {
	callback_list_user(error,"Something went wrong","error! Please check logs");
  }
  else
  {
	body = JSON.parse(body);
	var length = body.users.length;
	var name = '*No.*\t\t\t*Name*\n';
	for(i=0;i<length;i++)
	{
		var x = i+1;
		name = name + x + "\t\t\t" + body.users[i].name + "\n";
	}
	callback_list_user(null,name,null);
  }

});
}
module.exports = {
  list_user: function_call	// MAIN FUNCTION
  
}
