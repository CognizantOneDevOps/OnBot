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

/*Handles neo4j DB operations: read and write*/
var express = require("express");
var bodyParser = require("body-parser");
var app = express();
const instance = require('neode')
    .fromEnv()
    .with({
        Notification: require('./models/notification'),
        Problem: require('./models/problem'),
		Action: require('./models/action')
    });
app.use(bodyParser.json());

//write notification to neo4j
app.post('/neo4j/writeNotification', (req, res) =>{	
	console.log(req.body)
	var message=req.body;
	instance.create('Notification',message)
	.then(notify=>{
		console.log(notify._node);
		//create problem node if not exists and relate to notification
		instance.merge('Problem',message)
		.then(problem => {
			console.log(problem._node);
			notify.relateTo(problem,'Notified',message)
				.then(relationship=>{
					console.log(relationship._relationship);
					res.status(200).end("End of notification");
				});
	})
	});
})

//write resolution to neo4j
app.post('/neo4j/writeResolution', (req, res) =>{
	res.status(200).end()
	console.log(req.body)
	console.log("Creating action node");
	instance.merge('Action',req.body.Action)
		.then(action => {
			console.log(action._node);
			//relate action to notification
			instance.merge('Notification',req.body.PrimaryKey)
			.then(notify=>{
				console.log(notify._node);
				notify.relateTo(action,'ActionTaken',notify._node.properties)
				.then(res=>{
					console.log(res._relationship);
				})
		})
	});
})

//fetch the recommendations stored in neo4j
app.post('/neo4j/getDynamicRecommendation', (req, res) =>{
	console.log(req.body);
	var reco=[];
	for(var key in req.body){
		if(req.body.hasOwnProperty(key)){
		var id=key;
		var idValue=req.body[key];
		}
	}
	instance.cypher('MATCH (p:Notification {'+id+':\''+idValue+'\'})-[r:RECOMMEND]-(a) RETURN r,a')
    .then(rec => {
		console.log(rec);
		for(var k in rec.records){
			if(rec.records.hasOwnProperty(k)){
			var scores=rec.records[k]._fields[0].properties;
			var recommedation=rec.records[k]._fields[1].properties;
			reco[k]={Scores:scores,Recommendation:recommedation};
			}
		}
		return reco;
	}).then(a=>{
		console.log(a);
		res.status(200).end(JSON.stringify(a));
	}
	);
})

//fetch properties for static recommendation
app.post('/neo4j/getPropertiesForStaticRecommendation', (req, res) =>{
	console.log(req.body);
	for(var key in req.body){
		if(req.body.hasOwnProperty(key)){
		var id=key;
		var idValue=req.body[key];
		}
	}
	instance.cypher('MATCH (p:Notification {'+id+':\''+idValue+'\'}) RETURN p.toolName, p.Event, p.platformName')
    .then(a=>{
		console.log(a);
		res.status(200).end(JSON.stringify(a.records[0]._fields));
	});
})

var server = app.listen(8343, function () {
    console.log("Listening on port %s...", server.address().port);
})
