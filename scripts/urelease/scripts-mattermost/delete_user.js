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

﻿//DELETE USER
var request = require('request');
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
var function_call = function (urelease_url, username, password, user_name, callback_delete_user) {
var user_name = user_name;
var options = {
    url: urelease_url + '/users/name',
    auth: {
        'user': username,
        'pass': password
    }
};

function callback(error, response, body) {
    if (!error && response.statusCode == 200) {
        
body = JSON.parse(body);

        var len = body.length;
		var flag = 0;
for(i=0;i<len;i++)
{
        console.log(body[i].id + ' -- '+ body[i].name);
        if(body[i].name == user_name)
        {
                console.log(body[i].id)
				
				
				
				var options_delete = {
    url: urelease_url + '/users/'+body[i].id,
    method: 'DELETE',
    auth: {
        'user': username,
        'pass': password
    }
};

function callback_delete(error, response, body) {
    if (!error && response.statusCode == 200) {
       
		var str = 'User deleted with name : '+user_name;
		callback_delete_user("null",str,"null");
    }
	else
	{
		callback_delete_user("Error in deleting user","Error in deleting user","Error");
	}
}

request(options_delete, callback_delete);
				
			
		flag = 0;
		break;
        }
		else
		{
			
			flag = -1;
		}
}
if(flag == -1)
{
	callback_delete_user("Error in deleting user","Error in deleting user","Error");
}
    }
}

request(options, callback);

}




module.exports = {
  delete_user: function_call	// MAIN FUNCTION
  
}
