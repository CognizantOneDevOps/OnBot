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
Create a Teamcity user.

Dependencies:
 "request"
*/ 
var request = require('request');

var usr_crte = function(url,username,pwd,name,usrname,passwd,callback){

var data={name:name,username:usrname,password:passwd}
var result=""

var headers = {
    'Content-Type':     'application/json',
}

var options = { method: 'POST',
  url: url+'/app/rest/users',
  headers: headers,
  auth: {user:username,pass:pwd},
  body: JSON.stringify(data) };

request(options, function (error, response, body) {
	if(error){
		result= error;
		console.log(error);
	}
  if(response.statusCode == 200){
	  console.log("This stat");
	var json=JSON.parse(body);
	
  result  = "\n\tNew User Created Successfully Please find the details below.";
    result += "\n***************************************************************************************************************************";
    result += "\nid"+"\tname"+"\tuser name\tpassword";
    result += "\n***************************************************************************************************************************";
    result += "\n"+json["@id"]+"\t"+json["@name"]+"\t"+json["@username"]+"\t"+passwd;
	result += "\n***************************************************************************************************************************";
	result += "\nPlease change your password after your first login!";
	
  }else{
	result="User creation failed: "+body;
  } 
callback(result)
})}

module.exports = {
usr_crte:usr_crte
}
