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
var fs=require('fs');
var parser = require('xml2json');

var createuser= function (url, username, password, user, pswd, callback) {
var data='<user admin="false"><username>'+user+'</username><password>'+pswd+'</password></user>'
var xldeploy_url = url+'/deployit/security/user/'+user;
var options = {
  auth: {
        'user': username,
        'pass': password
    },
  method: 'POST',
  url: xldeploy_url,
  headers: 
   {'Content-Type':'application/xml'},
   body:data
   };

request(options, function (error, response, body) {
  if (error) {console.log(error); callback(error,null,null);}
  if(response.statusCode==200){
	  var list='';
	  var json = JSON.parse(parser.toJson(body));
	 
		list+="created user: "+json.user.username;

	 
	  console.log(list);
	  callback(null,list,null)
	  }

   if (response.statusCode!=200)
  {
	  console.log(body)
	  callback(null,null,body);
	  
	  
  }
});

}
module.exports = {
  createuser: createuser	// MAIN FUNCTION
  
}
