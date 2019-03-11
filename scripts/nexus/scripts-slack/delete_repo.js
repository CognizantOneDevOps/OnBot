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

var request = require("request");
var function_call = function (nexus_repourl, username, password, repoId, callback_delete_repo) {

var nexus_repourl = nexus_repourl+"/service/local/repositories/"+repoId;




var options = {
	    auth: {
        'user': username,
        'pass': password
    },
	method: 'DELETE',
  url: nexus_repourl,
  headers: 
   { 
     
     'content-type': 'application/json'
 },
  json: true };

function callback(error, response, body) {
    if (!error) {

	console.log(response.statusCode);
	if(JSON.stringify(response.statusCode) == '204')
	{


	callback_delete_repo(null,"Deleted Successfully",null);
	}
	else
	{
		

	callback_delete_repo("not200","Statuscode is not 200",null);
	}
    }
	else
	{
		callback_delete_repo("ServiceDown","Status code is not 200. Service is down.",null);

	}
	
}

request(options, callback);




}




module.exports = {
  repo_delete: function_call	// MAIN FUNCTION
  
}
