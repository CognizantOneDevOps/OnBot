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
Delete Teamcity project.

Dependencies:
 "request"
*/ 
var request = require('request');

var prj_del = function(url,username,pwd,projectid,callback){

var result = "";

var attach={
"attachments": [
	{
		"color": "#2eb886",
		"title": "Project Deletion",
		"text": ""
	}
]
};

var options = { method: 'DELETE',
  url: url+"/app/rest/projects/"+projectid,
  auth:{user:username,pass:pwd},
};

request(options, function (error, response, body) {
	if(error){
	result = error;
	console.log(error);
	}
  if (response.statusCode==204){
  attach.attachments[0].text="Project "+projectid+" Deleted successfully.";
  result=attach;
  } else{
	attach.attachments[0].text="Project Deletion failed: "+body;
	result=attach;
  }
  callback(result);
})

}

module.exports = {
prj_del:prj_del
}
