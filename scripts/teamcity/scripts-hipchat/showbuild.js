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
To Show builds.

Dependencies:
 "request"
 "xml2json"
*/ 
var request = require('request');
var parser = require('xml2json');

var bld_shw = function(url,username,pwd,bldId,bldtypid,callback){

var flag=true;
var result="";
var res_buildid="";
var buildId = bldId;

var options = { method: 'GET',
  url: url+"/app/rest/builds/",
  auth:{user:username,pass:pwd},
};

request(options, function (error, response, body) {
  if (error) {console.log(error)};
if(response.statusCode=200){
	var json=JSON.parse(parser.toJson(body));
	builds_count=json.builds.count;

if(error){
		console.log(error);
	}
	
for (var i=0;i<builds_count;i++){
	if (parseInt(json.builds.build[i].id) == buildId || json.builds.build[i].buildTypeId == bldtypid){
		flag=false;
		res_buildid=json.builds.build[i].id;
 		    result += "\n*******************************************************************************************************************************";
			result += "\nbuildid "+"\tbuildTypeId id"+"\t number"+"\tstatus"+"\tstate"+"\tweb url";
			result += "\n*******************************************************************************************************************************";		
			result += "\n"+json.builds.build[i].id+"\t"+json.builds.build[i].buildTypeId+"\t"+json.builds.build[i].number+"\t"+json.builds.build[i].status+"\t"+json.builds.build[i].state+"\t"+json.builds.build[i].webUrl;
			result += "\n*******************************************************************************************************************************"; 
			break;
	}
}

	if(flag){
 			result += "Build id provided is not valid!/Currently in Running Status!"; 
	}
 
} else{
	result=body;
	res_buildid="";
}
callback(result,res_buildid) 
}
)}

module.exports = {
bld_shw:bld_shw
}
