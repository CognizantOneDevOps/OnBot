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

//Function to create project with parameters url,username,password,project_id
var function_call = function (sonarurl, username, password, projectid, callback_project_create) {	
var sonar_url = sonarurl;
var username1 = username;
var password1 = password;
var project_id = projectid;

sonar_url = sonar_url+"api/projects/create?key="+project_id+"&name="+project_id;

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
	  callback_project_create("Something went wrong","Something went wrong","Something went wrong");
  }
  else if(response.statusCode == 200)
  {
	  callback_project_create(null,"",null);
  }
  else
  {
	  var str = JSON.stringify(body.errors);
	  callback_project_create(str,str,str);
  }

  
});
}
module.exports = {
  create_project: function_call	// MAIN FUNCTION
  
}
