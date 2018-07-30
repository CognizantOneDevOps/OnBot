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
var deletebranch = function (url, username, password, projectkey, reposlug, branchname, callback){
var branchdata={
    "name": "refs/heads/"+branchname,
    "dryRun": false
}
console.log(branchdata)
var options = { method: 'DELETE',
  url: url+'/rest/branch-utils/1.0/projects/'+projectkey+'/repos/'+reposlug+'/branches',
  auth: {
			'user': username,
			'pass': password
		},
  headers: 
   { 'content-type': 'application/json' },
  body:branchdata,
  json:true
	};
var data;
request(options, function (error, response, body) {
	console.log(response.statusCode)
  if(error){
	callback(error,null,null)
  }
  if (response.statusCode!=204){
	//body=JSON.parse(body)
	callback(null,null,"branch "+branchname+" doesn't exist")
  }
  if (response.statusCode==202){
	console.log(body);
	
	data=branchname+' deleted successfully'
	callback(null,data,null)
  }
  
});
}
module.exports = {
  deletebranch: deletebranch	// MAIN FUNCTION
  
}
