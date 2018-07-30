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

//Function to create project with parameters url,username,password,project_id
var function_call = function (sonarurl, username, password, projectid, callback_project_create) {
var project_id = projectid;

sonarurl = sonarurl+"api/projects/create?project="+project_id+"&name="+project_id;

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
	  callback_project_create(error,"Something went wrong","Something went wrong");
  }
  else if(response.statusCode == 200)
  {
	  callback_project_create(null,"Created successfully",null);
  }
  else
  {
	console.log(body)
	callback_project_create(body.errors[0].msg,"error","Couldn't create project. Please check logs.");
  }

  
});
}
module.exports = {
  create_project: function_call	// MAIN FUNCTION
  
}
