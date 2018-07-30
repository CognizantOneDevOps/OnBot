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

var request = require("request");
var createproj = function (url, username, password, projectkey, projectname, description, callback){
var projectdata={
    "key": projectkey,
    "name": projectname,
    "description": description
}
console.log(projectdata)
var options = { method: 'POST',
  url: url+'/rest/api/1.0/projects',
  auth: {
			'user': username,
			'pass': password
		},
  headers: 
   { 'content-type': 'application/json' },
  body:projectdata,
  json:true
	};
var data;
request(options, function (error, response, body) {
  if(error){
	callback(error,null,null)
  }
  if (response.statusCode!=201){
	
	callback(null,null,body.errors[0].message)
  }
  if (response.statusCode==201){
	console.log(body);
	
	data=projectname+' created with successfully '+body.links.self[0].href
	callback(null,data,null)
  }
  
});
}
module.exports = {
  createproj: createproj	// MAIN FUNCTION
  
}
