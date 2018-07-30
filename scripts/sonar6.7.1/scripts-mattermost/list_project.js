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

//Function to list the project with parameters url,username,password
var function_call = function (sonarurl, username, password, projectid, callback_list_project) {
var sonar_url = sonarurl;
var username1 = username;
var password1 = password;
var project_id = projectid;

sonar_url = sonar_url+"api/projects/search";

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
	
	console.log(body);
	console.log(error);
  if (error)
  {
	  callback_list_project("Something went wrong","Something went wrong",null);
  }
  else
  {
	  var name = '*No.*\t\t\t*Name [Project Key]*\n';
	body = JSON.parse(body);
	var length = body.components.length;
	for(i=0;i<length;i++)
	{
		var x = i+1;
		name = name+ x + "\t\t\t" + body.components[i].name + " [" + body.components[i].key + "]\n";
	}
	  callback_list_project(null,name,null);
  }

  
});
}
module.exports = {
  list_project: function_call	// MAIN FUNCTION
  
}
