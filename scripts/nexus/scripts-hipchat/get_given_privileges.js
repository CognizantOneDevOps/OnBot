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

var function_call = function (nexus_repourl, username, password, userid, callback_getsome_privileges) {

var userid = userid;
var nexus_repourl = nexus_repourl;
var request = require("request");
var url_link = nexus_repourl+"/service/local/privileges/"+userid;
var username = username;
var password = password;



var options = {
	    auth: {
        'user': username,
        'pass': password
    },
	method: 'GET',
  url: url_link,
  headers: 
   { 
     
     'content-type': 'application/json'
 }
 };

function callback(error, response, body) {
    if (!error) {

	if(JSON.stringify(response.statusCode) == '200')
	{
	var xmlText = body;
  
	var length_check = xmlText.split("<id>");
	var username = [];
	var status_name = [];
	var role = [];
	var final_answer = '';

	for(i=1; i<length_check.length; i++)
	{
  username[i] = xmlText.split("<id>")[i].split("</id>")[0];
  status_name[i] = xmlText.split("<name>")[i].split("</name>")[0];
  
  final_answer = final_answer +  "ID :: "+username[i]+"\t Name :: "+status_name[i]+"\n";
		
	}

	callback_getsome_privileges(null,final_answer,null);
	}
	else
	{
		callback_getsome_privileges("not200","Statuscode is not 200",null);
	}
    }
	else
	{
		callback_getsome_privileges("ServiceDown","Status code is not 200. Service is down.",null);
	}
	
}  

request(options, callback);

}

module.exports = {
  get_given_privileges: function_call	// MAIN FUNCTION
  
}
