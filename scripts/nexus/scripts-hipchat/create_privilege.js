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
var function_call = function (nexus_repourl, username, password, pri_name, repo_id, callback_create_privilege) {
	
	
	
	
	var nexus_repourl = nexus_repourl+'/service/local/privileges_target';
	var pri_name = pri_name;
	var repo_id = repo_id;
	var username = username;
	var password =password;

	
	
var options = { method: 'POST',
  url: nexus_repourl,
  headers: 
   { 
     'Content-Type': 'application/json',
      },
	 auth: {
        'user': username,
        'pass': password
    },
  body: 
   { data: 
      { name: pri_name,
        description: 'For Testing',
        type: 'target',
        repositoryId: repo_id,
        repositoryTargetId: '1',
        method: [ 'read', 'create', 'update', 'delete'] } },
  json: true };


request(options, function (error, response, body) {
  if (error)
  {
	  callback_create_privilege("Some error is there","Some error is there","Some error is there");
  }
  else
  {
	  callback_create_privilege(null,"Privilege created",null);
  }
});



}




module.exports = {
  create_privilege: function_call	// MAIN FUNCTION
  
}
