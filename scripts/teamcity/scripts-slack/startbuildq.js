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
Start a build.

Dependencies:
 "request"
 "xml2json"
*/ 
var request = require('request');
var parser = require('xml2json');
var fs = require('fs');

var bld_start = function(url,username,pwd,id,callback){

	var file= fs.createWriteStream(username+"_trigger_build.xml");
		file.write("<build><buildType id=\""+id+"\"/>");
		file.end("</build>");

var result="";
var res_buildid=""
		
var headers = {
    'Content-Type':'application/xml'
}

var options = { method: 'POST',
  url: url+'/app/rest/buildQueue',
  headers: headers,
  auth: {user:username,pass:pwd},
  body: fs.createReadStream(username+"_trigger_build.xml")
   };

request(options, function (error, response, body) {
	if(error){
		console.log(error);
	}
	if(response.statusCode == 200){
	var json=JSON.parse(parser.toJson(body));
	result = "Build started Successfully for buildTypeId "+json.build.buildTypeId+" with the buildid "+json.build.id;
	res_buildid= json.build.id;
  }else{
     result = body;
	 res_buildid="";
  }
	callback(result,json.build.id)
})
}

module.exports = {
bld_start:bld_start
}
