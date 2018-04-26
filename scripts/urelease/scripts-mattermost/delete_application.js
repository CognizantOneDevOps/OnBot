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

﻿var request = require('request');


process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
var request = require("request");

var function_call = function (urelease_url, username, password, app_name, callback_delete_application) {


var options = { method: 'GET',
  url: urelease_url + '/applications/?json&username='+username+'&password='+password+'&name='+app_name,
  headers:
   {
     accept: 'application/json' } };

request(options, function (error, response, body) {

if(body.length == ' ')
{
callback_delete_application("Error in deleting application","Error in deleting application","Error");
}

else{

body = JSON.parse(body);
var id = body[0].id;
console.log(id);




var options_del = {
    url: urelease_url + '/applications/'+id,
    method: 'DELETE',
    auth: {
        'user': username,
        'pass': password
    }
};

function callback_del(error, response, body) {
    if (!error && response.statusCode == 200) {
		var str = 'Application deleted with ID : '+id;
		callback_delete_application("null",str,"null");
        
    }
	else
	{
		callback_delete_application("Error in deleting application","Error in deleting application","Error");
	}
}

request(options_del, callback_del);

}
});
}




module.exports = {
  delete_application: function_call	// MAIN FUNCTION
  
}
