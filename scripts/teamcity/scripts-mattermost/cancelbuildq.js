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
Cancel a build in build queue.

Dependencies:
 "request"
*/ 

var request = require('request');

var bld_cancel = function(url,username,pwd,bldq,callback){

var result="";

var attach={
"attachments": [
	{
		"color": "#2eb886",
		"title": "Build Cancellation",
		"text": ""
	}
]
}

var headers = {
    'Content-Type':     'application/xml',
};

var options = { method: 'POST',
  url: url+'/app/rest/buildQueue/'+bldq,
  headers: headers,
  auth: {user:username,pass:pwd},
  body: "<buildCancelRequest comment='' readdIntoQueue='false' />" };

request(options, function (error, response, body) {
	if(error){
		console.log(error);
	}

  if(response.statusCode == 200){
	attach.attachments[0].text="Build ("+bldq+") Cancelled successfully.";
	result=attach;
  }else{
    attach.attachments[0].text="Build "+bldq+" Cancellation failed: "+body;
	result=attach;
  } 
callback(result)
})}

module.exports = {
bld_cancel:bld_cancel
}
