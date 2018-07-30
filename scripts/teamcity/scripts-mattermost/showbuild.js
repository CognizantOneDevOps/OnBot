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

var attach={
"attachments": [
	{
		"color": "#2eb886",
		"title": "Build Details",
		"text": "",
		"fields": [
			{
				"title": "",
				"value": "",
				"short": true
			},
			{
				"title": "",
				"value": "",
				"short": true
			},
			{
				"title": "",
				"value": "",
				"short": true
			},
			{
				"title": "",
				"value": "",
				"short": true
			},
			{
				"title": "",
				"value": "",
				"short": true
			},
			{
				"title": "",
				"value": "",
				"short": true
			}
		]
	}
]
}

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
		
			attach.attachments[0].text="Build details fetched successfully."
			attach.attachments[0].fields[0].title="BuildId";
			attach.attachments[0].fields[0].value=json.builds.build[i].id;
			attach.attachments[0].fields[1].title="BuildTypeId";
			attach.attachments[0].fields[1].value=json.builds.build[i].buildTypeId;
			attach.attachments[0].fields[2].title="Build Number";
			attach.attachments[0].fields[2].value=json.builds.build[i].number;
			attach.attachments[0].fields[3].title="Build Status";
			attach.attachments[0].fields[3].value=json.builds.build[i].status;
			attach.attachments[0].fields[4].title="Build State";
			attach.attachments[0].fields[4].value=json.builds.build[i].state;
			attach.attachments[0].fields[5].title="webUrl";
			attach.attachments[0].fields[5].value=json.builds.build[i].webUrl;
			result=attach;
			
			res_buildid=json.builds.build[i].id;
			break;
	}
}

	if(flag){
/* 			result += "Build id provided is not valid!/Currently in Running Status!"; */
			attach.attachments[0].text="Build id provided is not valid!/Currently in Running Status!: ";
			result=attach;
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
