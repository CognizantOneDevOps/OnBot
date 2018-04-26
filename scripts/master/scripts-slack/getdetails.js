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

var getdetailbot= function (botype,callback) {

var onbot_url = process.env.ONBOTS_URL+"/BotStore"

var options = { 

  method: 'get',
  url: onbot_url,
};

process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

request(options, function (error, response, body) {
var data={"BotName":"<Your Botname>","BotDesc":"<Desc>","bots":"<Bot eg:Jenkins>","BotType":"<BotType eg:Release Bot>","projectname":"<projectname>","lob":"<Lob>","adapter":"<your adapter>","slack":"<your_slack_bot_token>","repo":"<bot repo url>","updatedby":"<your name>"}
if(body){
	body=JSON.parse(body)
	var myflag=false 
	for(var i=0;i<body.length;i++){
		if(body[i].bots==botype){
			myflag=true
			console.log(body[i].bots)
			data.configuration=body[i].configuration;
			for(var j=0;j<data.configuration.length;j++){
				console.log(data)
				data.configuration[j]['value']="<your value>"
				
			
			}
			data="\n"+JSON.stringify(data)+"\n"
			callback(null,data,null)
			break;
		}
	}
	if(!myflag){console.log(myflag);callback(null,"no such tool",null)}

}
console.log(error)
})

}

module.exports = {
  getdetailbot: getdetailbot	// MAIN FUNCTION
  
}
