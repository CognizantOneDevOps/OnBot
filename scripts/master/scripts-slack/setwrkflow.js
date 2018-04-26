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

var request=require('request');
var fs=require('fs');

var setworkflow= function (botname,filename,callback) {

var auth_token = 'token='+ process.env.AUTH_TOKEN

var headers = {
    'Authorization': "Bearer " + process.env.AUTH_TOKEN
}
var privateurl;
var listoptions = { 

	method: 'get',
	url: "https://slack.com/api/files.list?"+auth_token
};

process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

request(listoptions, function (error, response, listbody) {

if(listbody){
	
	var listbody=JSON.parse(listbody)
	var data=listbody
	for (var i = 0 ; i < data.files.length; i++)
	{
		if(data.files.length > 0 && filename == data.files[i].name)
		{
			privateurl = data.files[i].url_private.replace(/\//g,"/");
			break;
			
		}	
	}
	console.log(privateurl)		
	var hitoptions = 
	{
		method: 'get',
		url: privateurl,
		headers:headers
	};
request(hitoptions, function (error, response, filebody) {
if(filebody){
	console.log("3");
	console.log(filebody)
	filebody=JSON.parse(filebody)
	var filedata=filebody
	filedata=filedata
	var onbot_url = process.env.ONBOTS_URL+"/editCoffee/workflow.json/"+botname

	var options = { 

	method: 'post',
	url: onbot_url,
	body: {"data":filedata},
	json: true
   };

	request(options, function (error, response, body) {

	console.log(error)
		
	if(body){
	console.log(body)
	if(body=="copied"){
		var removeoptions = {
		method: 'get',
		url: process.env.ONBOTS_URL+"/deletefiles/workflow.json"
		};
		request(removeoptions, function (error, response, removebody) {
			if(removebody){
				console.log(removebody)
			}
	   
		})
	}	
		
	}
	//console.log(body)
	callback(null,body,null)


	console.log(error)
})
}
})

console.log(botname)
}
})


}

module.exports = {
  setworkflow: setworkflow	// MAIN FUNCTION
  
}
