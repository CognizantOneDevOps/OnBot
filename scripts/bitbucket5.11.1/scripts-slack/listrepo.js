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
var listrepo = function (url, username, password, projectkey, callback){
var options = { method: 'GET',
  url: url+'/rest/api/1.0/projects/'+projectkey+'/repos',
  auth: {
			'user': username,
			'pass': password
		}
	};
var data;
request(options, function (error, response, body) {
  if (response.statusCode!=200){
	
	callback(null,null,body.errors[0].message)
  }
  if (response.statusCode==200){
	console.log(body);
	body=JSON.parse(body)
	data='*reposlug*\t\t\t\t\t*id*\t\t\t\t\t*name*\t\t\t\t\t*link*\t\t\t\t\t\t\t\t\t\t*clone*\n'
	for(i=0;i<body.values.length;i++){
		data+=body.values[i].slug+'\t\t\t'+body.values[i].id+'\t\t\t'+body.values[i].name+'\t\t\t'+body.values[i].project.links.self[0].href+'\t\t\t\t\t'+body.values[i].links.self[0].href+'\n'
		console.log(data)
		
	}
	callback(null,data,null)
  }
  if(error){
	callback(error,null,null)
  }
});
}
module.exports = {
  listrepo: listrepo	// MAIN FUNCTION
  
}
