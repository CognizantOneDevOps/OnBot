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
var parser = require('xml2json');
var titleget= function (url, username, password, name,callback) {



var xlrelease_url = url+"/api/v1/releases/byTitle?releaseTitle="+name
var options = { 
auth: {
        'user': username,
        'pass': password
    },
method: 'get',
  url: xlrelease_url,
 
  };
  
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
  if (response.statusCode==200){
	  console.log(body)
	  var json = body;
	  console.log(json)
	  callback(null,json,null);
  }
  });

  
};

module.exports = {
  titleget: titleget	// MAIN FUNCTION
  
}
