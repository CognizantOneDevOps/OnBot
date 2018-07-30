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
List the build types.

Dependencies:
 "request"
 "xml2json"
*/ 
var request = require('request');
var parser = require('xml2json');

var bld_typ_lst = function(url,username,pwd,callback){

var result="";

var options = { method: 'GET',
  url: url+"/app/rest/buildTypes",
  auth:{user:username,pass:pwd},
};

request(options, function (error, response, body) {
  if (error) {console.log(error)};  
	
var json=JSON.parse(parser.toJson(body));

buildTypes_count=json.buildTypes.count;

if(buildTypes_count>0){
	result += "\n*********************************************************************************************************************************************************************************************************************";
    result += "\nsno"+"\tbuild_type_id"+"\tbuild_type name"+"\tbuild_type_project_name"+"\tbuild_type_project_id"+"\tbuild_type_webUrl";
    result += "\n*********************************************************************************************************************************************************************************************************************";
		if(buildTypes_count==1){
			result += "\n"+(1)+"\t"+json.buildTypes.buildType.id+"\t"+json.buildTypes.buildType.name+"\t"+json.buildTypes.buildType.projectName+"\t"+json.buildTypes.buildType.projectId+"\t"+json.buildTypes.buildType.webUrl;
		}else{
			for (var i=0;i<buildTypes_count;i++){
				result += "\n"+(i+1)+"\t"+json.buildTypes.buildType[i].id+"\t"+json.buildTypes.buildType[i].name+"\t"+json.buildTypes.buildType[i].projectName+"\t"+json.buildTypes.buildType[i].projectId+"\t"+json.buildTypes.buildType[i].webUrl;
			}				
		}
    result += "\n**********************************************************************************************************************************************************************************************************************";
	} else {
		result	= "NO BuildTypes found"
	}
	
callback(result) 
})}

module.exports = {
bld_typ_lst:bld_typ_lst
}
