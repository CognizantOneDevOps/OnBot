var request=require('request');

var restartbot= function (botname,callback) {
	var options = {
		method: 'GET',
		url: process.env.ONBOTS_URL+"/deployAfterEdit/"+botname
	};
	request(options, function(error, response, body){
		if(error){
			callback(error,"Error occured")
		}
		else
		{
			if(body=='found'){
				console.log("please wait while the bot restarts..")
				var restartopt = {
					url: process.env.ONBOTS_URL+"/restartFound/"+botname,
					method: 'GET'
				}
				request(restartopt, function(error, response, body){
					if(error){
						callback(error,"Error occured")
					}
					else
					{console.log(body);
					callback(null,body)}
				});
			}
			else{
				console.log("restart script "+body+", preparing the restart script..")
				botobj = {}
				dbbot = {}
				botopt = {
					url: process.env.ONBOTS_URL+"/newbot/"+botname,
					method: "GET"
				}
				//getting bot object from mongodb
				request.get(botopt, function(error, response, body){
				if(body.indexOf('error')==-1){
					dbbot = JSON.parse(body)
					//assigning values to botobject
					botobj["BotName"]=dbbot.BotName
					botobj["type"]=dbbot.bots
					botobj["repo"]=dbbot.repo
					botobj["adapter"]=dbbot.adapter
					botobj["BotDesc"]=dbbot.BotDesc
					botobj["BotType"]=dbbot.BotType
					botobj["vars"]=[]
					for(i=0;i<dbbot.configuration.length;i++){
						botobj["vars"][i]=dbbot.configuration[i].bot_env+"="+dbbot.configuration[i].value;}
					if(botobj["adapter"]=='slack'){
						botobj["slack"]=dbbot.slack
						botobj["hipchatId"]=''
						botobj["hipchatPassword"]=''
						botobj["Matter"]=''
						botobj["MatterInURL"]=''
					}
					else if(botobj["adapter"]=='hipchat'){
						botobj["hipchatId"]=dbbot.hipchatId
						botobj["hipchatPassword"]=dbbot.hipchatPassword
						botobj["slack"]=''
						botobj["Matter"]=''
						botobj["MatterInURL"]=''
					}
					else{
						botobj["Matter"]=dbbot.Matter
						botobj["MatterInURL"]=dbbot.MatterInURL
						botobj["slack"]=''
						botobj["hipchatId"]=''
						botobj["hipchatPassword"]=''
					}
					if(botobj["type"]=="User Defined Bot"){
						botobj["addToExtJson"]=dbbot.addToExtJson
					}
					opt = {
						url: process.env.ONBOTS_URL+"/restartbot",
						method: "POST",
						headers: {"Content-type":"application/json"},
						body: botobj,
						json: true
					}
					//restarting bot
					request.post(opt, function(err, res, body){
						console.log("err: "+err)
						if(body=="Error in Resarting Hubot"){
							console.log("There has been an error while deploying the bot. You may look at the logs for more details.");
							callback(body,"Error occured");
						}
						else{
							console.log("The bot "+botobj.BotName+" has been redeployed successfully with your changes.")
							callback(null,"Restarted");
							deletescript = {
								url: process.env.ONBOTS_URL+"/deletefiles/restart"+botobj.BotName+".sh",
								method: "GET"
							}
							//deleting the restartscript created locally inside OnBots server
							request.get(deletescript, function(err, res, body){
								if(res.body != 'successfully deleted'){
									console.log("**Warning**: Unable to delete the script file. Refer bot logs for details")
									console.log(err)
								}
							});
							dbbot["status"]='on'
							mongodata = {
								url: process.env.ONBOTS_URL+"/newbot/"+botname,
								method: "PUT",
								headers: {"Content-type":"application/json"},
								body: dbbot,
								json: true
							}
							//updatingbot status to mongodb
							request.put(mongodata, function(err, res, body){
								if(body==undefined){
									console.log(err)
									console.log("Couldn't modify bot status in mongodb. Refer to logs file for more details.")
								}
								else{
									console.info("Updated bot status in db successfully.")
								}
							});
						}
					});
				}
				else{
					callback(body,"Error occured")
				}
				});
			}
		}
	})
}

module.exports = {
  restartbot : restartbot	// MAIN FUNCTION
  
}