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

var hubotScript = require('./hubotScripts.js');
var kubectl = require('./kubectlApi.js');
var exec = require('child_process').exec;
var fs = require('fs');
var config = require('./config/config.json');
var slackadapter = 'slack';
var hipchatadapter = 'hipchat';
var mattermostadapter = 'mattermost';

var deployBot = function(app){

	//deploys a new bot
	app.post('/deployBot',function(req,res) {
		console.log(req.body)
		var repo = req.body.repo;
		var botname = req.body.BotName;
		var type = req.body.bots;
		var slack
		var hipchatId 
		var hipchatPassword
		var mattermostToken
		var mattermostInURL
		var addToExtJson = {};
		if(req.body.adapter==slackadapter){
			slack = req.body.slack;
		}
		if(req.body.adapter==hipchatadapter){
			hipchatId = req.body.hipchatId
			hipchatPassword = req.body.hipchatPassword
		}
		if(req.body.adapter==mattermostadapter){
			mattermostToken = req.body.Matter
			mattermostInURL = req.body.MatterInURL
		}
		var str ="";
		var v = {};
		var envArr = [];
		var npmArr = '';
		v = req.body.vars; // GETTING DATA AS JSON OBJECT
		
		if(type == 'User Defined Bot')
		{
			envArr = v[1];
			npmArr = v[0];
			addToExtJson = req.body.addToExtJson;
		}
		else{
		for(var i = 0; i < v.length; i++)
		{
			 envArr[i] = v[i]; // ASSIGNING VALUE OF JSON TO ARRAY NEEDS FIX
		}
		}	

		if(req.body.adapter==slackadapter){
			var botScript = hubotScript.createScript(repo, botname, slack, slackadapter, envArr, npmArr, type, addToExtJson);
		}
		if(req.body.adapter==hipchatadapter){
			var hipchat = hipchatId+" "+hipchatPassword
			var botScript = hubotScript.createScript(repo, botname, hipchat, hipchatadapter, envArr, npmArr, type, addToExtJson);
		}
		if(req.body.adapter==mattermostadapter){
			var mattermost = mattermostToken+" "+mattermostInURL
			var botScript = hubotScript.createScript(repo, botname, mattermost, mattermostadapter, envArr, npmArr, type, addToExtJson);
		}
		var yaml = hubotScript.createYaml(botname);
		kubectl.createContainer(botname,req.body.adapter, function(error, result) {
			if(error)
			{
				console.log("error response")
				res.send("Error in Creation");
			}
			else{
				console.log("success response")
				res.send("Success! "+botname+" is UP and Running");
			}
		});
	});

	//stops a running bot
	app.post('/stopbot',function(req,res){
	
		var botname = req.body.BotName;
		console.log(botname)
		var script = hubotScript.stopScript(botname);
		kubectl.stopscripts(botname, function(error, result) {
			if(error)
			{
				console.log(error)
				res.send("Error in Stopping Hubot");
			}
			else{
				console.log(result)
		res.send("Success! "+botname+" is Stopped");
			}
		});

});

	//restarts a stopped/running bot
	app.post('/restartbot',function(req,res){
		
		
		var repo = req.body.repo;
		var botname = req.body.BotName;
		var type = req.body.type;
		var slack
		var hipchatId 
		var hipchatPassword
		var mattermostToken
		var mattermostInURL
		var addToExtJson = {};
		if(req.body.adapter==slackadapter){
			slack = req.body.slack;
		}
		if(req.body.adapter==hipchatadapter){
			hipchatId = req.body.hipchatId
			hipchatPassword = req.body.hipchatPassword
		}
		if(req.body.adapter==mattermostadapter){
			mattermostToken = req.body.Matter
			mattermostInURL = req.body.MatterInURL
		}		
		//added
		var v = {};
		v = req.body.vars;
		var envArr = [];
		var npmArr = '';
		if(type == 'User Defined Bot')
		{
			envArr = v[1];
			npmArr = v[0];
			addToExtJson = req.body.addToExtJson;
		}
		else{
		for(var i = 0; i < v.length; i++)
		{
			 envArr[i] = v[i]; // ASSIGNING VALUE OF JSON TO ARRAY NEEDS FIX
		}
		}
		if(req.body.adapter==slackadapter){
			var botScript = hubotScript.restartScript( botname, slack, slackadapter, envArr, npmArr, type, addToExtJson);
		}
		if(req.body.adapter==hipchatadapter){
			var hipchat = hipchatId+" "+hipchatPassword
			var botScript = hubotScript.restartScript( botname, hipchat, hipchatadapter, envArr, npmArr, type, addToExtJson);
		}
		if(req.body.adapter==mattermostadapter){
			var mattermost = mattermostToken+" "+mattermostInURL
			var botScript = hubotScript.restartScript( botname, mattermost, mattermostadapter, envArr, npmArr, type, addToExtJson);
		}	
		console.log("Script created ")
		

		kubectl.restartscripts(botname, function(error, result) {
			if(error)
			{
				res.send("Error in Restarting Hubot");
			}
			else{
		res.send("Success! Hubot is Restarted");
			}
		});

	}); 

	//gets the pod status in which the bot is deployed
	app.get('/getpodStatus/:botname',function(req,res){
		

		kubectl.getPodStatus(req.params.botname, function(error, result) {
			//result.id=req.params.id;
			if(error)
			{
				res.send(result);
			}
			//console.log(result)
			res.send(result);
			
		});
		
	});
	
	//deletes the .sh files created while deploying/restarting/stopping a bot
	app.get('/deletefiles/:filename',function(req,res){
		var name=req.params.filename;

		fs.unlink('./app/config/'+name, (err) => {
		  if (err) throw err;
		  res.send('successfully deleted');
		  console.log('successfully deleted');
		});
		
	})

	//for fetching log data through masterbot
	app.get('/download/:botname/:nol',function(req,res){
		nol = req.params.nol;
		var filename = req.params.botname+".log";
		var path = "app/config/"+filename;// FILE CREATION PATH PRE-DEFINED
		var writerStream = fs.createWriteStream(path, {overwrite: false});		
		kubectl.readlog(req.params.botname,function(err,result){
		if(err){
			res.send(err+". Make sure you have given a botname which is deployed.")
		}
		else{
			if(nol=='all'){
				writerStream.write(result);
				writerStream.end();
				res.download(__dirname+"/config/"+filename, filename, function(err){
					if(err) throw err
					else{
						fs.unlink("app/config/"+filename);
					}
				});
			}
			else{
				var i = 0;
				logarray = result.split('\n')
				if(logarray.length>nol){
					result = ''
					for(i=logarray.length-nol;i<logarray.length;i++)
					{
						if(i==logarray.length-1){result += logarray[i];}
						else{result += logarray[i] + "\n"}
					}
				}
				writerStream.write(result);
				writerStream.end();
				res.download(__dirname+"/config/"+filename, filename, function(err){
					if(err) throw err
					else{
						fs.unlink("app/config/"+filename);
					}
				});
			}
		}
		});
		
	});
	
	//get workflow.json file content
	app.get('/getworkflowjson/:filename/:botname',function(req,res){
		var filename=req.params.filename;
		var botname=req.params.botname;
		kubectl.coffeecontenet(filename,botname,function(err,result){
		if(err){
			res.send(err)
			}
			else{
			res.send(result);

			}
		});
	});
	//creates the shell script for restarting the bot
	createRestart=function(bot,botname,callback){
		var repo = bot.repo;
		var type = bot.type;
		var slack;
		var hipchatId;
		var hipchatPassword;
		if(bot.adapter==slackadapter){
			slack = bot.slack;
		}
		if(bot.adapter==hipchatadapter){
			hipchatId = bot.hipchatId
			hipchatPassword = bot.hipchatPassword
		}
		if(bot.adapter==mattermostadapter){
			mattermostToken = req.body.Matter
			mattermostInURL = req.body.MatterInURL
		}
		var v = {};
		v = bot.vars;
		var envArr = [];
		var npmArr = '';
		if(type == 'User Defined Bot')
		{
			envArr = v[1];
			npmArr = v[0];
		}
		else{
		for(var i = 0; i < v.length; i++)
		{
			 envArr[i] = v[i]; // ASSIGNING VALUE OF JSON TO ARRAY NEEDS FIX
		}
		}
		if(bot.adapter==slackadapter){
			var script = hubotScript.restartScript(botname, slack, slackadapter, envArr, npmArr, type);
		}
		if(bot.adapter==hipchatadapter){
			var hipchat = hipchatId+" "+hipchatPassword;
			var script = hubotScript.restartScript(botname, hipchat, hipchatadapter, envArr, npmArr, type);
		}
		if(bot.adapter==mattermostadapter){
			var mattermost = mattermostToken+" "+mattermostInURL
			var script = hubotScript.restartScript(botname, mattermost, mattermostadapter, envArr, npmArr, type);
		}
		kubectl.restartscripts(botname, function(error, result) {
			if(error)
			{
				callback(error,"Error");
			}
			else{
				callback(null,"Success");
			}
		});
	}
	
	//saving coffeescript/workflow.json from master bot
	app.post('/editCoffee/:filename/:botname',function(req,res){
		var botname=req.params.botname;
		var filename = req.params.filename;
		var content= "";
		content = req.body.data;
		var path = 'app/config/' + filename;
		hubotScript.createCoffee(path, botname, content);
		kubectl.editCoffee(botname, filename, path, function(err,result){
		if(err){
			res.send("error in copying coffee file");
		}
		else{
		if(result == botname)
		{
			res.send("copied");
		}
		else
			res.send("failed");
		}
		});
	});
	
	//restart bot if restart script is found inside container
	app.get('/restartFound/:botname',function(req,res){
		var botname = req.params.botname;
		kubectl.executeRestart(botname, function(err,result3){
			if(!err){
				res.send("restarted");
			}
			else{
				res.send("couldn't restart");
			}
		});
	});
	
	//create restart script if restart script is not found inside container
	app.post('/restartNotFound/:botname',function(req,res){
		var bot = req.body.bot;
		var botname = req.params.botname;
		console.log("++++++" + JSON.stringify(req.body.bot));
		var restart=createRestart(bot, botname, function(error,result2){
				if(error)
					res.send(error);
				else
					res.send(result2);
			});
	});
	
	//Deploying the bot after editing workflow.json from master bot
	app.get('/deployAfterEdit/:botname',function(req,res){
		var botname=req.params.botname;
		kubectl.checkRestartScript(botname, function(err,result1){
				console.log("deploy " + result1);
				console.log(err);
				if(result1 == "not found")
				{
					res.send(result1);
				}
				else{
					res.send(result1);
				}
			});
	});
};

module.exports=deployBot;
