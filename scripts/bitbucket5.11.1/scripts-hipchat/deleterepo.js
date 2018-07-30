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
var deleterepo = function (url, username, password, projectkey, reponame, callback){
var options = { method: 'DELETE',
  url: url+'/rest/api/1.0/projects/'+projectkey+'/repos/'+reponame,
  auth: {
			'user': username,
			'pass': password
		}
	};
var data;

request(options, function (error, response, body) {

  if (response.statusCode!=202){
	console.log("error:::"+body)
	body=JSON.parse(body)
	callback(null,null,body.errors[0].message)
  }
  if (response.statusCode==202){
	console.log(body);
	
	data=reponame+' deleted successfully'
	callback(null,data,null)
  }
  if(error){
	callback(error,null,null)
  }
});
}
module.exports = {
  deleterepo: deleterepo	// MAIN FUNCTION
  
}
