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
List the build queue.

Dependencies:
 "request"
 "xml2json"
*/ 
var request = require('request');
var parser = require('xml2json');

var buildqueue_lst = function(url,username,pwd,callback){

var result="";

var buildqueue_count=0;

var options = { method: 'GET',
  url: url+"/app/rest/buildQueue",
  auth:{user:username,pass:pwd},
};

request(options, function (error, response, body) {
  if (error) {console.log(error)};
  
 var json=JSON.parse(parser.toJson(body));


 if(json.builds.count>0){
		buildqueue_count=json.builds.count;
		result += "\n*******************************************************************************************************************************";
		result += "\nsno"+"\tbuild id"+"\tbuildqueue_Type_Id"+"\tState"+"\tproject url";
		result += "\n*******************************************************************************************************************************";
		if(buildqueue_count==1){
			result += "\n"+(1)+"\t"+json.builds.build.id+"\t"+json.builds.build.buildTypeId+"\t"+json.builds.build.state+"\t"+json.builds.build.webUrl;
		}else{
			for (var i=0;i<buildqueue_count;i++){
				result += "\n"+(i+1)+"\t"+json.builds.build[i].id+"\t"+json.builds.build[i].buildTypeId+"\t"+json.builds.build[i].state+"\t"+json.builds.build[i].webUrl;
			}				
		}
		result += "\n*******************************************************************************************************************************";
	} else {
		result	= "NO Build Queue found"
	}
  
callback(result) 
})}

module.exports = {
buildqueue_lst:buildqueue_lst
}
