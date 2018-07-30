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
var createrepo = function (url, username, password, projectkey, reponame, callback){
var repodata={
    "name": reponame,
    "scmId": "git",
    "forkable": true
}
console.log(repodata)
var options = { method: 'POST',
  url: url+'/rest/api/1.0/projects/'+projectkey+'/repos',
  auth: {
			'user': username,
			'pass': password
		},
  headers: 
   { 'content-type': 'application/json' },
  body:repodata,
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
	
	data=reponame+' created successfully with reposlug '+body.slug+'\n'+body.links.clone[1].href
	callback(null,data,null)
  }
  
});
}
module.exports = {
  createrepo: createrepo	// MAIN FUNCTION
  
}
