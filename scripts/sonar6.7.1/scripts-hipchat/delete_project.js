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

//Function to delete project with parameters url,username,password,project_id
var function_call = function (sonarurl, username, password, projectid, callback_project_delete) {

sonarurl = sonarurl+"api/projects/delete?project="+projectid;

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
	body = JSON.parse(body);
	callback_project_delete(error,"error","Something went wrong");
  }
  else if(response.statusCode == 204)
  {
	  callback_project_delete(null,"Deleted successfully",null);
  }
  else
  {
	body = JSON.parse(body);
	console.log(body)
	callback_project_delete(body.errors[0].msg,"error","Couldn't delete project. Please check logs.");
  }

  
});
}
module.exports = {
  delete_project: function_call	// MAIN FUNCTION
  
}
