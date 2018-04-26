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
var function_call = function (nexus_url, nexus_user_id, nexus_password, userid, callback_delete_user) {
	nexus_repourl = nexus_url
	   random_password=(Math.random()*1e39).toString(36);
   random_password = random_password.toLowerCase();
	nexus_repourl = nexus_repourl + "/service/local/users/"+userid;

	
	
	
	
	var options = {
		    auth: {
        'user': nexus_user_id,
        'pass': nexus_password
    },
	method: 'DELETE',
  url: nexus_repourl,
  headers: 
   {
     'content-type': 'application/json' },
  json: true };
	
	
	
	function callback(error, response, body) {
    if (!error) {

	
	if(JSON.stringify(response.statusCode) == '204')
	{
	

	callback_delete_user(null,"Successfully deleted",null);
	}
	else
	{
		

	callback_delete_user(error,response,null);
	}
    }
	else
	{
		callback_delete_user(error,"Some error is there",null);

	}
	
}

request(options, callback);
	
	}

module.exports = {
  delete_user: function_call	// MAIN FUNCTION
  
}
