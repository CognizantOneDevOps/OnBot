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

var function_call = function (nexus_repourl, username, password, callback_getall_repo) {



var Table = require('cli-table');

var nexus_repourl = nexus_repourl;
var request = require("request");
var url_link = nexus_repourl+"/service/local/repositories";
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
	var length_check = xmlText.split("<name>");
	var name = [];
	var url = [];
	var provider = [];
	var id_repo = [];
	var final_answer = "*No.*\t\t\t*ID*\t\t\t*Name*\t\t\t*Provider*\t\t\t*RepoUrl*\n";

	for(i=1; i<length_check.length; i++)
	{
		name[i] = xmlText.split("<name>")[i].split("</name>")[0];
		url[i] = xmlText.split("<contentResourceURI>")[i].split("</contentResourceURI>")[0];
		provider[i] = xmlText.split("<provider>")[i].split("</provider>")[0];
		id_repo[i] = xmlText.split("<id>")[i].split("</id>")[0];
		final_answer = final_answer+i+ "\t\t\t"+id_repo[i]+"\t\t\t"+name[i]+"\t\t\t"+provider[i]+"\t\t\t"+url[i]+"\n";
	}

	callback_getall_repo(null,final_answer,null);
	}
	else
	{
		callback_getall_repo("not200","Statuscode is not 200",null);
	}
    }
	else
	{
		callback_getall_repo("ServiceDown","Status code is not 200. Service is down.",null);
	}
	
}  
  
  
request(options, callback);

}

module.exports = {
  get_all_repo: function_call	// MAIN FUNCTION
  
}
