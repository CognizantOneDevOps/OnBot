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
var function_call = function (nexus_url, nexus_user_id, nexus_password, userid, roleid, userpassword, callback_create_user) {
	nexus_repourl = nexus_url;
   
	nexus_repourl = nexus_repourl + "/service/local/users";
	var options = {
		    auth: {
        'user': nexus_user_id,
        'pass': nexus_password
    },
	method: 'POST',
  url: nexus_repourl,
  headers: 
   {
     'content-type': 'application/json' },
  body: 
   { data: 
      { email: 'testing@example.com',
        userId: userid,
        status: 'active',
        roles: [ roleid ],
        password: userpassword } },
  json: true };
	
	
	
	function callback(error, response, body) {
    if (!error) {

	
	if(JSON.stringify(response.statusCode) == '201')
	{
	

	callback_create_user(null,"",null);
	}
	else
	{
		

	callback_create_user("something went wrong","something went wrong","something went wrong");
	}
    }
	else
	{
		callback_create_user("something went wrong","something went wrong","something went wrong");

	}
	
}

request(options, callback);
	
	
	
	
	
	
	
	}




module.exports = {
  create_user: function_call	// MAIN FUNCTION
  
}
