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

//This file handles all mongodb related operations of OnBots

var mongojs = require('mongojs');
var jwt=require('jsonwebtoken');

var kubectl = require('./kubectlApi.js');
const ensureLoggedIn = require('connect-ensure-login').ensureLoggedIn();

var github = require('octonode');
var gitclient = github.client();
var ghrepo = gitclient.repo('silverlane/testhubot');

var config = require('./config/config.json');
var db = mongojs(config.MongoDB+'/'+config.dbName,config.botCollections);
var api = require('api-npm');

var multer  = require('multer');
var storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'public/botuploadImg/')
    },
    filename: function (req, file, cb) {
        cb(null, file.originalname+ '-' + Date.now()+'.jpg')
    }
});
var upload = multer({ storage: storage });


var appRouter = function(app){

app.get('/BotStore',function(req,res){
		console.log("inside botstore")
		db.BotStore.find(function(err,docs){
			var botstore=docs;
			db.Bots.aggregate([{ $match:{$or: [ { void: false }, {void: { "$exists" : false } } ]}},
				{$group:{_id:"$bots",count:{$sum:1}}}
				],function(err,docs){
				if(err){
					res.send(err);
				}
			if(docs){
				console.log("inside if")
			var instance=docs;
			for(var i=0;i<botstore.length;i++){
			for(var j=0;j<instance.length;j++){
			
			if(botstore[i].bots==instance[j]._id){
			
			
			botstore[i].instance=instance[j].count;
			break;

			}
			else
			{

			
			botstore[i].instance=0;
			console.log(botstore)
			}
			}
			}
	res.json(botstore);
			}
			else{console.log("inside else");res.send("No such tool found")}
		})

			
		});		
});

app.get('/availablebotsformanage',function(req,res){
	
		
	db.Bots.find({$or: [{ void: false }, {void: { "$exists" : false } } ]}).sort({timestamp: -1},function(err,docs){
		if(err){
			res.send(err);
		}
		if(docs){
		for (var i = 0; i < docs.length; i++) {
			docs[i].slackStatus="loading..";
			docs[i].hostIP="loading..";
			docs[i].phase="loading..";

		}
		res.json(docs);
		}
	});
		
});


app.post('/newbot',function(req,res){
	if(req.body!='undefined' && req.body.body!=''){
	
	db.Bots.insert(req.body, function(err,docs){
		if(err){
			res.send(err);
		}
		if(docs){
			res.json(docs);
		}
	});
	}
});

app.delete('/newbot/:botname',function(req,res){
	
	
	var botname=req.params.botname;
	
	var del=kubectl.deleteContainer(botname);
	//Void Records
	db.Bots.findAndModify({query:{BotName:botname},
		update:{$set:{void:true,slack:""}},
		new:false},function(err,docs){
			if(err){
			res.send(err)
			}
			res.json(docs);
			
		});
});

app.get('/newbot/:botname',function(req,res){
	var botname = req.params.botname;
	console.log(botname)
	db.Bots.findOne({BotName:botname},function(err,docs){
		if(err){
			console.log("err::"+err)
			res.send(err)
		}
		if(!docs){console.log("no bot");res.send("error bot not found")}
		else{
		console.log("docs::"+docs)
		res.json(docs);
		}
	});
});

app.put('/newbot/:botname',function(req,res){
	var botname = req.params.botname;
	if(req.body!='undefined' && req.body!=''){
	db.Bots.findAndModify({query:{BotName:botname},
		update:{$set:{BotName:req.body.BotName,BotDesc:req.body.BotDesc,bots:req.body.bots,BotType:req.body.BotType,slack:req.body.slack,status:req.body.status,
			configuration:req.body.configuration,addToExtJson:req.body.addToExtJson,hipchatId:req.body.hipchatId,hipchatPassword:req.body.hipchatPassword,adapter:req.body.adapter,Matter:req.body.Matter,MatterInURL:req.body.MatterInURL}},
		new:true},function(err,docs){
			if(err)
			{
				res.send(err)
			}
			if(!docs){res.send("error in updating bot")}
			else{
			res.json(docs);
			}
			
		});
	}
});


//validate whether botname already exists
app.get('/validate/:botname',function(req,res){
	var botname=req.params.botname;
	console.log(botname)
	db.Bots.findOne({BotName:botname},function(err,docs){
		if(err) throw err;
		if(!docs){
			res.send("valid botname");
		}
		else{
			res.send("botname already exist");
		}

	});
});


};
module.exports=appRouter;
