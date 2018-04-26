/**
* Create shell scripts for Addding,deleting and restarting bot
* Creates yaml file for containers and workflow.json file for bots
*/
var fs = require("fs");
var config = require('./config/config.json');
var mongojs = require('mongojs');
var db = mongojs(config.MongoDB+'/'+config.dbName,config.botCollections);

var checkBotname = function (botname,callback) {
	var mybotname=botname;
	
	db.Bots.findOne({BotName:botname},function(err,docs){
		if(err) throw err;
		
		if(!docs){
			callback("not found")
		}
		else{
			callback("found")
		}
	});
}

//Create shell script for adding bot
module.exports.createScript = function (repo, botname, slack, adapter, arr, npms, type, addToExtJson) {
		console.log("type"+type)
		var botname = botname;
		checkBotname(botname,function(check){
		if(check=="found"){
		console.log('botname '+botname+' found... proceeding for normal execution')
		var botlink = repo;
		var slack_token = slack;
		var env_string = arr;
		var botType = type;
		var path = "app/config/"+botname+".sh";// FILE CREATION PATH PRE-DEFINED 
		var port = '8787';// PRE-DEFINED
		var writerStream = fs.createWriteStream(path, {overwrite: false});
		// GETTING THE ZIP NAME FROM THE BOTLINK
		var botlink_arr = botlink.split("/");
		var final_bot_zip_name = botlink_arr[ botlink_arr.length - 1 ];
		
		botlink = "`wget "+botlink+"`";
		var data = "#!/bin/bash\n";
		if(botType=='BuildOn')
		{
		data = data + "apt-get -m update && apt-get install -y git && apt-get install -y fs " + "\n";	
		}
		data = data + botlink + "\n";
		data = data + "`/usr/bin/unzip "+final_bot_zip_name+" -d myhubot`\n";
		data = data + "chmod -R 755 myhubot\n";
		data = data + "rm -rf "+final_bot_zip_name+"\n";
		data = data + "cd myhubot\n";
		if(adapter=='slack')
		{
			data = data + "rm -rf scripts-hipchat scripts-mattermost\n"
			data = data + "mv scripts-slack scripts\n"
		}
		if(adapter=='hipchat')
		{
			data = data + "rm -rf scripts-slack scripts-mattermost\n"
			data = data + "mv scripts-hipchat scripts\n"
		}
		if(adapter=='mattermost')
		{
			data = data + "export MATTERMOST_ENDPOINT=/hubot/incoming\n"
			data = data + "rm -rf scripts-slack scripts-hipchat\n"
			data = data + "mv scripts-mattermost scripts\n"
		}
		if(botType == 'User Defined Bot')
		{
			data = data + "npm install "+npms+"\n";
			var npmToInit = [];
			npmToInit = npms.split(' ');
			npms='';
			for(i = 0;i < npmToInit.length; i++)
			{
				//checking whether to add an npm module to external-scripts.json file inside hubot
				if(addToExtJson[npmToInit[i]]=='Yes'){
					if(npms==''){npms = npmToInit[i];}
					else{npms = npms + "\\\",\\\"" + npmToInit[i];}
				}
			}
			if(npms==''){data = data + "sed -i -e \"s/]/\\\"hubot-elasticsearch-logger\\\"]/\" external-scripts.json\n";}
			else{data = data + "sed -i -e \"s/]/\\\"hubot-elasticsearch-logger\\\",\\\""+npms+"\\\"]/\" external-scripts.json\n";}
		}
		data = data + "sed -i -e \"s/npm install/# /g\" bin/hubot\n";
		data = data + "sed -i -e \"s/ctsbot/"+botname+"/g\" bin/hubot\n";
		
		data = data + "apt-get install nodejs-legacy\n";
		data = data + "sed -i -e \"s/hubot-today/hubot-"+botname+"/g\" scripts/lib/logger.js\n";
		data = data + "export EXPRESS_PORT="+port+"\n";
		data = data + "export PATH=\"node_modules/.bin:node_modules/hubot/node_modules/.bin:$PATH\"\n";
		data = data + "export HUBOT_NAME="+botname+"\n";
		data = data + "export "+slack_token+"\n";
		data = data + "";
		if(botType == 'User Defined Bot')
		{
			var x = "export "+ env_string + "\n";
			data = data + x;
		}
		else{
		for (i = 0; i < env_string.length; i++) {
		       var x = "export "+ env_string[i] + "\n";
			data = data + x;
		    }
		}
		 var configArr = config.ENV; 
		 for (i = 0; i < configArr.length; i++) {
		       var x = "export "+ configArr[i] + "\n";
			data = data + x;
		    }
		if(adapter=='slack'){
			data = data + "nohup ./bin/hubot -a slack > hubot.log &\n";
		}
		if(adapter=='hipchat'){
			data = data + "export HUBOT_HIPCHAT_JOIN_ROOMS_ON_INVITE=true HUBOT_HIPCHAT_JOIN_PUBLIC_ROOMS=true\n"
			data = data + "nohup ./bin/hubot -a hipchat > hubot.log &\n";
		}
		if(adapter=='mattermost'){
			data = data + "nohup ./bin/hubot -a mattermost > hubot.log &\n";
		}
		if(botType == 'Insights'){
			data = data + "sh installcurl.sh\n"
		}
		data = data + "echo $EXPRESS_PORT \n";
		data = data + "echo \"success\"";

		writerStream.write(data);
		writerStream.end();
		
		}
		else{console.log('Bot not found')}
		});
	}

//Create shell script for restarting bot
module.exports.restartScript = function (botname, slack, adapter, arr, npms, type, addToExtJson) {
		var botname = botname;
		checkBotname(botname,function(check){
		if(check=="found"){
		var slack_token = slack;
		var env_string = arr;

		var path = "app/config/restart"+botname+".sh";// FILE CREATION PATH PRE-DEFINED 
		var port = 8787;// PRE-DEFINED
		var writerStream = fs.createWriteStream(path, {overwrite: false});
		
		var data = "#!/bin/bash\n";
		data = data + "ps aux | grep -ie "+botname+" | grep node_modules | awk '{print $2}' | xargs kill -9"+"\n";
		data = data + "cd /home/myhubot\n";
		if(type == 'User Defined Bot')
		{
			data = data + "npm install "+npms+"\n";
			data = data + "echo [] > external-scripts.json\n";
			var npmToInit = [];
			npmToInit = npms.split(' ');
			npms='';
			for(i = 0;i < npmToInit.length; i++)
			{
				//checking whether to add an npm module to external-scripts.json file inside hubot
				if(addToExtJson[npmToInit[i]]=='Yes'){
					if(npms==''){npms = npmToInit[i];}
					else{npms = npms + "\\\",\\\"" + npmToInit[i];}
				}
			}
			if(npms==''){data = data + "sed -i -e \"s/]/\\\"hubot-elasticsearch-logger\\\"]/\" external-scripts.json\n";}
			else{data = data + "sed -i -e \"s/]/\\\"hubot-elasticsearch-logger\\\",\\\""+npms+"\\\"]/\" external-scripts.json\n";}
		}
		data = data + "export EXPRESS_PORT="+port+"\n";
		data = data + "export PATH=\"node_modules/.bin:node_modules/hubot/node_modules/.bin:$PATH\"\n";
		data = data + "export "+slack_token+"\n";
		data = data + "export HUBOT_NAME="+botname+"\n";
		if(type == 'User Defined Bot')
		{
			var x = "export "+ env_string + "\n";
			data = data + x;
		}
		else{
		for (i = 0; i < env_string.length; i++) {
		       var x = "export "+ env_string[i] + "\n";
			data = data + x;
		    }
		}
		 var configArr = config.ENV; 
		 for (i = 0; i < configArr.length; i++) {
		       var x = "export "+ configArr[i] + "\n";
			data = data + x;
		    }
		if(adapter=='slack'){
			data = data + "nohup ./bin/hubot -a slack > hubot.log &"+"\n";
		}
		if(adapter=='hipchat'){
			data = data + "export HUBOT_HIPCHAT_JOIN_ROOMS_ON_INVITE=true HUBOT_HIPCHAT_JOIN_PUBLIC_ROOMS=true\n"
			data = data + "nohup ./bin/hubot -a hipchat > hubot.log &\n";
		}
		if(adapter=='mattermost'){
			data = data + "export MATTERMOST_ENDPOINT=/hubot/incoming\n"
			data = data + "nohup ./bin/hubot -a mattermost > hubot.log &\n";
		}
		data = data + "echo \"success\""+"\n";
		writerStream.write(data);
		writerStream.end();
		}
		else{console.log('Bot not found')}
		});
	}

//Create shell script for stopping bot
module.exports.stopScript = function(botname) { 		
	var botname=botname;
	checkBotname(botname,function(check){
	if(check=="found"){
	var path ="app/config/stop"+botname+".sh"
	var writerStream = fs.createWriteStream(path, {overwrite: false});
	var data = "ps aux | grep -ie "+botname+" | awk '{print $2}' | xargs kill -9"+"\n";
	data = data + "echo \"success\"";
	writerStream.write(data);
	writerStream.end();
	}
	});
} 
//Create yaml file for Kubenetes Container
module.exports.createYaml = function (botname) {
		var inputfile = "app/config/ubuntu.yaml"; // READ FROM CURRENT DIRECTORY
		var destfile = "app/config/"+botname+".yaml";// COPY YAML DESTINATION

		var stream = fs.createWriteStream(destfile);
		var data = "";
		var change_part = "nameofbot";//MENTIONED IN SAMPLE YAML

		var final_botname = botname;// DESIRED BOT NAME IN YAML

		        readline = require('readline');
		        instream = fs.createReadStream(inputfile);
		        outstream = new (require('stream'))();
		        rl = readline.createInterface(instream, outstream);		     
		    rl.on('line', function (line) {        
			if(line.includes(change_part)){
			line = line.replace(/nameofbot/g, final_botname);									
			}
			data = data + line + "\n";	
		    });
		    
		    rl.on('close', function (line) {			
			stream.write(data);
			stream.end();        
		    });
	}
//create files locally (inside /app/config directory)
module.exports.createCoffee = function (path, botname, content) {
	console.log(typeof(content));
	console.log(path)
	checkBotname(botname,function(check){
	if(check=="found"){
	var writerStream = fs.createWriteStream(path, {overwrite: false});
	writerStream.write(JSON.stringify(content));
	writerStream.end();
	}
	});
}