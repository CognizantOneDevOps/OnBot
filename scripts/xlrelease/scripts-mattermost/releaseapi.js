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

var request=require('request');
var fs=require('fs');
var template= function (url, username, password, filename, callback) {


var file='./'+filename;


fs.readFile(file, 'utf8', function (err,data) {
  if (err) {
    return console.log(err);
  }
var xlrelease_url = url+"/api/v1/templates"
var options = { 
auth: {
        'user': username,
        'pass': password
    },
method: 'post',
  url: xlrelease_url,
  headers: 
   {'Content-Type':'application/json'},
  body:data
  };
  console.log(username+password);
  request(options, function (error, response, body) {
	
	
	
		
  if (error)
  {
	  callback(error,null,null);
  }
  if (response.statusCode!=200)
  {
	  console.log(body)
	  callback(null,null,body);
	  
	  
  }
  if (response.statusCode==200)
  {
	var resultid=JSON.parse(body);
	console.log(body)
	  console.log("created template")
	 callback(null,"created template with release id: "+resultid.id,null);
  }
  });
  
  });
  
};
module.exports = {
  template: template	// MAIN FUNCTION
  
}
