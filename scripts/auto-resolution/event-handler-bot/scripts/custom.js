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

/*Listens for notifications and resolutions. Sends data to neo4jDBHandler. 
Gets recommendations from recommendation engine and post to slack*/
var request =require('request')
var fs = require('fs')
var problemconfig =require('./problemconfig.json')
var resolconfig =require('./resolutionconfig.json')
var recommendationjson =require('./getrecommendation.json')
var datajson=require('./tokenizer.json')
var filterjson=require('./filter.json')

const RECO = /(set)\s(static|dynamic)/i;
const TEST = /.+/i
module.exports = (robot) => {
	robot.hear(TEST, (res) => {
		console.log(res.match)
		var data= res.match["input"]
		//Parse the notification
		var json={}
		var extnjson={}
		const str = data;
		var  m;
		for(var i=0;i<datajson["NotificationDefinition"].length;i++){
			var notificationFlag=false;
			const notificationRegex = eval(datajson["NotificationDefinition"][i].notificationRegex)
			if ((m = notificationRegex.exec(str)) !== null) {
				for(var j=1;m[j]!=null;j++){
					notificationFlag=true;
					console.log('Found match,'+j+' : '+m[j]);
					json[datajson["NotificationDefinition"][i].notificationGroupindex[j-1].name]=m[j]
					if(datajson["NotificationDefinition"][i].notificationGroupindex[j-1].name===filterjson.statuskey)
						{
							extnjson=problemconfig[m[j]]
							console.log(Object.assign(json, extnjson))
						}
				}
			}
			if(notificationFlag===true)
				break;
		}
		//Write notification to neo4j
		if(json.hasOwnProperty(filterjson.statuskey) && json.hasOwnProperty(filterjson.uniqueid) && json[filterjson.statuskey] !== filterjson.excludevalue){
			var options = {
					uri: 'http://'+process.env.NEO4JHANDLER_IP+'/neo4j/writeNotification',
					method: 'POST',
					headers: {
					'Content-type': 'application/json'
					},
					body:json ,
					json:true
				}
				request(options, (error, response, body) => {
					console.log(error);
					console.log(body);
				});
			console.log("********writeNotification**********")
			console.log(json)
			var recojson=recommendationjson;
			//Get recommendation
			for(var key in recojson["PrimaryKey"]){
				recojson["PrimaryKey"][key]=json[key];	
			}				
			console.log("********getRecommendation**********")
			console.log(recojson)
			//Clear the interval if recommendation in received
			var myVar = setInterval(function(){
			var options = {
					uri: 'http://'+process.env.RECOMMENDATION_ENGINE_IP+'/neo4j/getRecommendation',
					method: 'POST',
					headers: {
					'Content-type': 'application/json'
					},
					body:recojson,
					json:true}
				request(options, (error, response, body) => {
					console.log("getRecommendation")
					console.log(error);
					console.log(body);
					if(body.attachments[0].actions[0].options.length>1){
						clearInterval(myVar);
						res.send(body);
						console.log("Cleared interval");
					}
				})
			}, 1000);
		}
	});
	
	
	robot.router.post('/writeResolution', function(req, response) {
		console.log(req.body);
		//Parse the resolution
		const str = req.body.command;
		var c,json;
		for(var i=0;i<datajson["ActionDefinition"].length;i++){
			var actionFlag=false;
			const resolutionRegex = eval(datajson["ActionDefinition"][i].resolutionRegex)
			if ((c = resolutionRegex.exec(str)) !== null) {
				for(var j=1;c[j]!=null;j++){
					actionFlag=true;
					console.log('Found match,'+j+' : '+c[j]);
					json=resolconfig[c[j]];
				}
			}
			if(actionFlag===true)
				break;
		}
		for(var key in json["PrimaryKey"])
			json["PrimaryKey"][key]=req.body.triggerid
		//Write resolution to neo4j
		var options = {
				uri: 'http://'+process.env.NEO4JHANDLER_IP+'/neo4j/writeResolution',
				method: 'POST',
				headers: {
				'Content-type': 'application/json'
				},
				body:json ,
				json:true
			}
		request(options, (error, response, body) => {
				console.log("**********writeResolution**********")
				console.log(error);
				console.log(body);
				
			})
		response.send("success")
	})
	
	//Set recommendation to static or dynamic
	robot.respond(RECO, (res) => {
		console.log(res.match[1]+"::"+res.match[2]+"::"+res.match[3])
			if(res.match[2]==="static"){
				recommendationjson.DynamicRecommendation=false
			}
			else{
				recommendationjson.DynamicRecommendation=true
			}
			console.log(recommendationjson)
			fs.writeFile("./scripts/getrecommendation.json", JSON.stringify(recommendationjson), (err) => {
			if (err) {
				console.error(err);
			return;
			};
			console.log("File has been created");
			});
		res.send("recommendation set to "+res.match[2])
	})
}
