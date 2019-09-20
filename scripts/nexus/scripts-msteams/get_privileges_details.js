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

var function_call = function (nexus_repourl, username, password, name, getall_privileges_name) {

var nexus_repourl = nexus_repourl;
var request = require("request");
var url_link = nexus_repourl+"/service/local/privileges";
var username = username;
var password = password;
var name_search = name;


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
  //console.log(status_name[i]);
  //console.log(name_search);
  var check_name_from_coffee = status_name[i].split("-")[0].trim();
  if(name_search == check_name_from_coffee)
  {
	  name_search = username[i] + " " + name_search;
	  //console.log(name_search);
	  
  }
  
  final_answer = final_answer +  "ID :: "+username[i]+" Name :: "+status_name[i]+"<br>";
		
	}
getall_privileges_name(null,name_search,null);
	
	}
	else
	{
		getall_privileges_name("Something is wrong","Something is wrong",null);
	}
    }
	else
	{
		getall_privileges_name("Something is wrong","Something is wrong",null);
	}
	
}  
  
  
request(options, callback);




}




module.exports = {
  get_privileges_details: function_call	// MAIN FUNCTION
  
}
