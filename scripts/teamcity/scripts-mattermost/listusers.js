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

/*Description:
List Teamcity Projects.

Dependencies:
 "request"
 "xml2json"
*/ 
var request = require('request');
var parser = require('xml2json');

var usr_lst = function(url,username,pwd,callback){

var result ="";

var options = { method: 'GET',
  url: url+"/app/rest/users",
  auth:{user:username,pass:pwd},
};

request(options, function (error, response, body) {
  if (error) {console.log(error)};
 
var json=JSON.parse(parser.toJson(body));
var usr_count=json.users.count;

	result += "\n*******************************************************************************************************************************";
    result += "\nid"+"\tusername"+"\tname";
    result += "\n*******************************************************************************************************************************";
	if(usr_count==1){
		result += "\n"+json.users.user.id+"\t"+json.users.user.username+"\t\t"+json.users.user.name;
	}else{
		for (var i=0;i<usr_count;i++){
			result += "\n"+json.users.user[i].id+"\t"+json.users.user[i].username+"\t\t"+json.users.user[i].name;
		}
	}
    result += "\n*******************************************************************************************************************************"; 

callback(result) 
})}

module.exports = {
usr_lst:usr_lst
}
