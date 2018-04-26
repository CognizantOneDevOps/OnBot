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

var request=require('request'); // Requiring npm request package

var fs=require('fs'); // Requiring npm file system package

var stopbot= function (botname,callback) {

console.log(botname)
var onbot_url = process.env.ONBOTS_URL+"/stopbot"

var options = { 

method: 'post',
  url: onbot_url,
  body:{"BotName" : botname},
  json:true
   };

process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

request(options, function (error, response, body) {

if(body){
	

callback(null,body,null)
if(body.indexOf("Success")!=-1){
	var getoptions = { 

	method: 'get',
	url: process.env.ONBOTS_URL+"/newbot/"+botname,
	
	
   };
   request(getoptions, function (error, response, getbody) {
	   if(getbody){
		   getbody=JSON.parse(getbody)
		   getbody.status="off";
		   
		  var updateoptions = { 

			method: 'put',
			url: process.env.ONBOTS_URL+"/newbot/"+botname,
			body:getbody,
			json:true
	
			}; 
			request(updateoptions, function (error, response, updatebody) {
				if(updatebody){
					
				console.log(error)}
			})
	   }
	   
   })
}
}
console.log(error)
})

}

module.exports = {
  stopbot: stopbot	// MAIN FUNCTION
  
}
