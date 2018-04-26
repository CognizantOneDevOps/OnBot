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

var elasticsearch = require('../node_modules/elasticsearch/src/elasticsearch');
var config = require('./config/config.json');
Sediment = require('sediment');

var elasticApi = function(app){
	var client = new elasticsearch.Client({
		host: config.ElasticSearch,
  		log: 'trace'
	});


//fetches bot metrices from elasticsearch
app.get('/analytics/:Botname',function(req,res) {
	var botname=req.params.Botname;

	client.search({
  	index: 'hubot-monitor',
  	type: 'Health',
	
  	body: {
  		
    	"query": {
    		"match":{"Botname":botname}
     },
     "size":"1",
     "sort" : [{"timestamp" : {"order" : "desc"}}]
  }
},function (error, response) {
        if (error) {
            res.send(response);
          } else {
			res.send(response);
          }
	});
});

//fetches total conversation and hitmiss count of bot conversations from elasticsearch
app.get('/totalconv/:Botname',function(req,res) {
	var botname=req.params.Botname;
	var jsonobj={};
	
	client.count({
  	index: "hubot-"+botname,
  	type: 'message',
	
  	body: {
  		"query": {
			"bool":{
				must:[{"match":{"type":"chat"}},
					{"match":{"user":botname}}]
			}
		
		},
   
    	
		}
		},
		function (error, response) {
        if (error) {
		console.log('error occured in hits' + error);
		jsonobj.totalconv=0;
		if(Object.keys(jsonobj).length==2){
		console.log(error);
		res.send(jsonobj);
		} 
          } else {
             console.log('got response in hits');
			jsonobj.totalconv=response.count;
			if(Object.keys(jsonobj).length==2){
			res.send(jsonobj);
			} 
          }
	});
	
		client.count({
  	index: "hubot-"+botname,
  	type: 'message',
	
  	body: {
  		"query": {
			"bool":{
				must:[{"match":{"type":"chat"}},
					{"match":{"user":botname}},
					{"term":{"message.keyword":"Sorry, I didn't get you"}}]
			}
		
		},
    
    	
		}
		},
		function (error, response) {
        if (error) {
		console.log('error occured in hits' + error);
           
		jsonobj.hitmiss=0;
		if(Object.keys(jsonobj).length==2){
		console.log(error);
		res.send(jsonobj);
		} 
          } else {
             console.log('got response in hits');
			jsonobj.hitmiss=response.count;
			if(Object.keys(jsonobj).length==2){
			res.send(jsonobj);
			} 
          }
	});
	
});

//for fetching chat data through masterbot
	app.get('/downloadchat/:botname',function(req,res){
		var filename = req.params.botname+"_chat.log";
		var path = "app/config/"+filename;// FILE CREATION PATH PRE-DEFINED
		var writerStream = fs.createWriteStream(path, {overwrite: false});
		var ind = "hubot-"+req.params.botname
		console.log(ind)		
		client.search({
  		index: ind,
  		type: 'message',
		"size": 1000,
  		body: {
    		"query": {
        		"query_string" : {
			"default_field" : "type",
            		"query" : "Chat",
           		"analyze_wildcard" : "false",
            		"default_operator" : "AND"
     		}
		},
       "sort" : [{"timestamp" : {"order" : "desc"}}]
	}
	},function (error, response) {
		var str
        if (error) {
			str="no such bot"
			
			console.log("err"+str)
			writerStream.write(str);
		writerStream.end();
		res.download(__dirname+"/config/"+filename, filename, function(err){
			if(err) throw err
				else{
					fs.unlink("app/config/"+filename);
				}
		});
          } else {
		console.log("response\n"+str)
		for(i=0;i<response.hits.hits.length;i++)
		{
			
	 	 str+= response.hits.hits[i]._source.user+': '+response.hits.hits[i]._source.message+"\n";
		
		}
		writerStream.write(str);
		writerStream.end();
		res.download(__dirname+"/config/"+filename, filename, function(err){
			if(err) throw err
				else{
					fs.unlink("app/config/"+filename);
				}
		});
          }
	});		
});

}

module.exports=elasticApi;
