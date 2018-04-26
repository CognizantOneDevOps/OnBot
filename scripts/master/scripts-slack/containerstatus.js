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

var fs=require('fs'); // Requiring npm file-system package

var constatus= function (botname,callback) {

console.log(botname)
var onbot_url = process.env.ONBOTS_URL+"/getpodStatus/"+botname

var options = {

  method: 'get',
  url: onbot_url,

};
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

request(options, function (error, response, body) {

if(body){
	if(body)
	console.log(body)
	body=JSON.parse(body)
	var data= "      HostIP      |	     PodIP 	   | 	  Status      |			   MMCallbackURL                 \n"
	// Checking if mmcallURL or the port where hubot is exposed
	if(body.mmcallURL=="NA" ||body.nodePort=="NA"){
		data+=body.hostIP+"     |    "+body.podIP+"       |        "+body.phase+"       |          "+"NA"+"       "
	}
	else{
	data+=body.hostIP+"    |       "+body.podIP+"      |       "+body.phase+"      |     "+'http://'+body.mmcallURL+':'+body.nodePort+'/hubot/incoming'+"  "
	}

callback(null,data,null)

}

console.log(error)
})

}

module.exports = {
  constatus: constatus	// MAIN FUNCTION
  
}
