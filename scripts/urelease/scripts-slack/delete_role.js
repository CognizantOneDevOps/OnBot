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

process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
var request = require('request');
var function_call = function (urelease_url, username, password, role_name, callback_delete_role) {

var options = {
    url: urelease_url + '/roles/name',
    auth: {
        'user': username,
        'pass': password
    }
};

function callback(error, response, body) {
    if (!error && response.statusCode == 200) {
body = JSON.parse(body);
var len = body.length;
var flag = 11;
for(i=0;i<len;i++)
{


if(body[i].name == role_name){

																							var id = body[i].id;
																							var options_del = {
																								url: urelease_url + '/roles/'+id,
																								method: 'DELETE',
																								auth: {
																									'user': username,
																									'pass': password
																								}
																							};
																							function callback_del(error, response, body) {
																								if (!error) {
																									console.log(body);	
																									callback_delete_role("null","Role deleted","null");
																								}
																								else
																								{
																									callback_delete_role("Error in deleting role","Error in deleting role","Error");
																								}
																							}

																							request(options_del, callback_del);
																							





	flag = 0;
		break;

}
else
{
	//callback_delete_role("Error in deleting role","Error","Error");
	flag = -1;
}



    }
if(flag == -1)
{
	callback_delete_role("Error in deleting role","Error in deleting role","Error");
}
	

}


}
request(options, callback);
}


module.exports = {
  delete_role: function_call	// MAIN FUNCTION
  
}
