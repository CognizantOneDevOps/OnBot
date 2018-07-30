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

/*Get static or dynamic recommendation and handle interactive messages of slack*/
var express = require("express");
var bodyParser = require("body-parser");
var app = express();
app.use(bodyParser.json());
var fileSystem=require("fs");
var request = require('request');
var TimSort = require('timsort');
var MasterJson = require('./masterJSON.js');
//require('dotenv').config();
var urlencodedParser = bodyParser.urlencoded({ extended: false });
var trigger;

//score comparator for tim sort
function scoreComparator(a,b) {
	return b.Score-a.Score;
}

app.post('/neo4j/getRecommendation', (req, res) =>{
	var id;
	for(var key in req.body.PrimaryKey)
		if(req.body.PrimaryKey.hasOwnProperty(key))
			id=req.body.PrimaryKey[key];
	var staticJsonHead="{\"text\":\"For the notification with ID:"+id+" choose a remediation action from below:\",\"response_type\":\"in_channel\",\"attachments\":[{\"text\":\"Recomendation\",\"fallback\":\"If you could read this message, you'd be choosing something fun to do right now.\",\"color\":\"#3AA3E3\",\"attachment_type\":\"default\",\"callback_id\":\""+id+"\",\"actions\":[{\"name\":\"action on cloudbot\",\"text\":\"Pick a action...\",\"type\":\"select\",\"options\":[";
	var staticJsonTail="{\"text\":\"Others...\",\"value\":\" \"}]}]}]}";
	if(req.body.DynamicRecommendation===true){
		console.log("Sending dynamic json");
		//get dynamic recommendation from Neo4jDBhandler
		var options = {
							uri: 'http://'+process.env.NEO4JHANDLER_IP+'/neo4j/getDynamicRecommendation',
							method: 'POST',
							headers: {
							'Content-type': 'application/json'
							},
							body:req.body.PrimaryKey,
							json:true
						}
		request(options, (error, response, body) => {
			console.log("*****************=================************")
			if(error)
			console.log(error);
			else{
				var tempJson='';
				console.log(body);
				var recommendationArray=[];
				for(var k in body){
					if(body.hasOwnProperty(k)){
					var scores=body[k].Scores;
					var reco=body[k].Recommendation[req.body.Recommendation['RecommendationLabel']];
					var totalScore=0;
					for(key in scores){
						if(scores.hasOwnProperty(key))
						totalScore+=scores[key];
					}
					recommendationArray[k]={Recommendation:reco,Score:totalScore};
				}
				}
				//sorting the scores in descending order
				TimSort.sort(recommendationArray,scoreComparator);
				for(var i=0;i<5;i++){
					if(recommendationArray[i])
						tempJson+="{\"text\":\""+recommendationArray[i].Recommendation+"\",\"value\":\""+recommendationArray[i].Recommendation+"\"},";
				}
				var recommendationJson=staticJsonHead+tempJson+staticJsonTail;
				console.log(recommendationJson);
				res.status(200).end(recommendationJson);
			}
		});
	}
	else{
		console.log("Sending static json");
		var staticoptions = {
					uri: 'http://'+process.env.NEO4JHANDLER_IP+'/neo4j/getPropertiesForStaticRecommendation',
					method: 'POST',
					headers: {
					'Content-type': 'application/json'
					},
					body:req.body.PrimaryKey,
					json:true
				}
		request(staticoptions, (error, response, body) => {
			console.log("*****************=================************")
			if(error)
			console.log(error);
			else {
				var tempJson='';
				MasterJson.masterJson.get(body[0]).get(body[1]).forEach(function (key) {
					tempJson+="{\"text\":\""+ key.get(body[2]) +"\",\"value\":\""+ key.get(body[2]) +"\"},";
				});
				var recommendationJson=staticJsonHead+tempJson+staticJsonTail;
				console.log(recommendationJson);
				res.status(200).end(recommendationJson);
			}
		});
	}
 }) 
 
 function sendMessageToSlackResponseURL(responseURL, JSONmessage){
    var postOptions = {
        uri: responseURL,
        method: 'POST',
        headers: {
            'Content-type': 'application/json'
        },
        json: JSONmessage
    }
    request(postOptions, (error, response, body) => {
        if (error){
            // handle errors as you see fit
			console.log(error);
        }
    })
}
 
 
 //middleware operations to handle interactive messages
 app.post('/hubot/ai-callback', urlencodedParser, (req, res) =>{
    res.status(200).end() // best practice to respond with 200 status

    var actionJSONPayload = JSON.parse(req.body.payload) // parse URL-encoded payload JSON string
    if(actionJSONPayload.hasOwnProperty("trigger_id")){
			trigger=actionJSONPayload.callback_id;
			console.log(trigger)
		}
    if(actionJSONPayload.type==="interactive_message"){
    var postPayload=actionJSONPayload.actions[0]
	var test =postPayload.selected_options
    var action =test[0].value;
	postPayload.action=action;

	//json to be displayed in the dialog box
	var data={
	  "callback_id": trigger,
	  "title": "Request Your command",
	  "submit_label": "Submit",
	  "elements": [
		{
		  "type": "text",
		  "label": "Command",
		  "name": "Command",
			  "value":"@<yourbotname> "+action
		}
	  ]
	}

	//open dialog box to enter command
	var url = 'https://slack.com/api/dialog.open?token='+process.env.EVENTHANDLER_USER_TOKEN+'&trigger_id='+actionJSONPayload.trigger_id+'&dialog='+JSON.stringify(data)
	var diaoptions = {
			uri: url,		  
			method: 'POST',
			json: true
		}
		request(diaoptions, (error, response, body) => {
			console.log("****dialogresponse******");
			console.log(error);
			console.log(body);
		})
	var message = {
			"text": action+" chosen for "+actionJSONPayload.original_message.attachments[0].callback_id+" with trigger "+trigger,
			"replace_original": true
		}
	sendMessageToSlackResponseURL(actionJSONPayload.response_url, message);
	}else{	
			var slackurl="https://slack.com/api/chat.postMessage?token="+process.env.SLACK_LEGACY_TOKEN+"&channel="+actionJSONPayload.channel.id+"&text="+actionJSONPayload.submission.Command
	var options = {
		url: slackurl,
		method: 'POST'

	}
	// Start the request
	request(options, function (error, response, body) {
			console.log("****postchat response******");
			console.log(error)
			console.log(body)
	})
	var resolnjson={"command":actionJSONPayload.submission.Command.trim(),"triggerid":actionJSONPayload.callback_id}
	console.log(resolnjson)
	var resoloptions = {
        url: 'http://'+process.env.EVENTHANDLER_IP+'/writeResolution',
        method: 'POST',
        headers: {
            'Content-type': 'application/json'
        },
        body:{"command":actionJSONPayload.submission.Command.trim(),"triggerid":actionJSONPayload.callback_id},
        json: true
		}
		
		request(resoloptions, (error, response, body) => {
			console.log("****writeResolution response******");
			console.log(error)
			console.log(body)
		})
	}
})


 var server = app.listen(5000, function () {
    console.log("Listening on port %s...", server.address().port);
})
