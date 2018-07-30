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

var prj_lst = function(url,username,pwd,callback){

var result = "";

var options = { method: 'GET',
  url: url+"/app/rest/projects",
  auth:{user:username,pass:pwd},
};

request(options, function (error, response, body) {
  if (error) {console.log(error)};
  
var json=JSON.parse(parser.toJson(body));

proj_count=json.projects.count;

if(proj_count > 0){
	result+= "\n*******************************************************************************************************************************";
    result += "\nsno"+"\tproject id"+"\tproject name"+"\tproject url";
    result += "\n*******************************************************************************************************************************";
	if(proj_count == 1){
		result += "\n"+(1)+"\t"+json.projects.project.id+"\t"+json.projects.project.name+"\t"+json.projects.project.webUrl;
	}else{
		for (var i=0;i<proj_count;i++){
			result += "\n"+(i+1)+"\t"+json.projects.project[i].id+"\t"+json.projects.project[i].name+"\t"+json.projects.project[i].webUrl;
		}		
	}
	result += "\n*******************************************************************************************************************************";
}else{
	result += "\nNo projects found. Please create a new Project!";
}

callback(result) 
})}

module.exports = {
prj_lst:prj_lst
}

