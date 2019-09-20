###
Description:
 OneDevOps-OnBots Editbot functionality implementation for hubot

Configurations:
 MATTERMOST_URL: your mattermost server url
 ONBOTS_URL: your OneDevOps-OnBots server url

Commands:
 @botname get details for <mongodb_objectId_of_the_bot> -> shows details of the bot along with json template required to redeploy it
 @botname redeploy <mongodb_objectId_of_the_bot> with config <mattermost_file_id_of_user's_jsonfile> -> redeploys bot with the given json file data and updates the
 changes in mongodb
###

fs = require('fs') # Requiring npm file-system package

request = require('request') # Requiring npm request package

auth_token = 'token='+ process.env.AUTH_TOKEN

headers = {'Authorization': "Bearer " + process.env.AUTH_TOKEN }

process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

module.exports = (robot) ->
	robot.respond /getBotDetails (.*)/i, (msg) ->
		botname = msg.match[1]
		options = {
			url: process.env.ONBOTS_URL+"/newbot/"+botname,
			method: "GET"
		}
		request.get options, (error, response, body) ->
			if typeof(body)!="object" && body.indexOf("error")==-1
				jsonbody = JSON.parse(body)
				dt = "==========================\n"
				dt += " * BotName"+"	||	"+jsonbody.BotName+"\n * Bot description"+"	||	"+jsonbody.BotDesc+"\n * Bot Type"+"	||	"+jsonbody.bots+"\n"
				dt +=" * Adapter"+"	||	"+jsonbody.adapter+"\n * Bot Status"+"	||	"+jsonbody.status+"\n"
				if jsonbody.adapter=='slack'
					dt += " * Slack Token"+"	||	"+jsonbody.slack+"\n\nConfigurations"
				else if jsonbody.adapter=='mattermost'
					dt += " * Mattermost Incoming Url"+"	||	"+jsonbody.MatterInURL+"\n* Mattermost Outgoing Token"+"	||	"+jsonbody.Matter+"\n\nConfigurations"
				else
					dt += " * Hipchat User ID"+"	||	"+jsonbody.hipchatId+"\n * Hipchat Password"+"	||	XXXXXX\n\nConfigurations"
				for i in [0...jsonbody.configuration.length]
					if jsonbody.configuration[i].type=='password'
						dt += "\n * "+jsonbody.configuration[i].key+"	||	XXXXXX"
					else
						dt += "\n * "+jsonbody.configuration[i].key+"	||	"+jsonbody.configuration[i].value
				msg.send dt
				dt = "JSON template for editing bot: "+botname+"\n"
				jsontemplate = "{\"BotName\":\""+jsonbody.BotName+"\",\"type\":\""+jsonbody.bots+"\",\"repo\":\""+jsonbody.repo+"\",\"BotDesc\":\""+jsonbody.BotDesc+"\",\"id\":\""+jsonbody._id+"\",\n\"configuration\":["
				for i in [0...jsonbody.configuration.length]
					if i==jsonbody.configuration.length-1
						jsontemplate += "{\"key\":\""+jsonbody.configuration[i].key+"\",\"type\":\""+jsonbody.configuration[i].type+"\",\"bot_env\":\""+jsonbody.configuration[i].bot_env+"\",\"value\":\""+jsonbody.configuration[i].value+"\"}]"
					else
						jsontemplate += "{\"key\":\""+jsonbody.configuration[i].key+"\",\"type\":\""+jsonbody.configuration[i].type+"\",\"bot_env\":\""+jsonbody.configuration[i].bot_env+"\",\"value\":\""+jsonbody.configuration[i].value+"\"},"
				if jsonbody.bots=="User Defined Bot"
					jsontemplate += ",\"addToExtJson\":\""+jsonbody.addToExtJson+"\""
				jsontemplate += ",\"adapter\":\""+jsonbody.adapter+"\""
				if jsonbody.adapter=='slack'
					jsontemplate += ",\"slack\":\""+jsonbody.slack+"\"}"
				else if jsonbody.adapter=='mattermost'
					jsontemplate += ",\"MatterInURL\":\""+jsonbody.MatterInURL+"\",\"Matter\":\""+jsonbody.Matter+"\"}"
				else
					jsontemplate += ",\"hipchatId\":\""+jsonbody.hipchatId+"\",\"hipchatPassword\":\""+jsonbody.hipchatPassword+"\"}"
				msg.send dt+"`"+jsontemplate+"`"
			else
				msg.send "Bot doesn't exist"
	
	robot.respond /editbot (.*) (.*)/i, (msg) ->
		botname = msg.match[1]
		filename = msg.match[2]
		console.log(filename)
		dbbot = {}
		dbbotopt = {
			url: process.env.ONBOTS_URL+"/newbot/"+botname,
			method: "GET"
		}
		request.get dbbotopt, (error, response, body) ->
			console.log(body)
			dbbot = JSON.parse(body)
			listoptions = {
				method: "GET",
				url: "https://slack.com/api/files.list?"+auth_token
			}
			request.get listoptions,(error, response, listbody) ->
				listbody=JSON.parse(listbody)
				data=listbody
				for i in [0...data.files.length]
					if(data.files.length > 0 && filename == data.files[i].name)
						privateurl = data.files[i].url_private.replace(/\//g,"/");
						break;
				hitoptions = {
					method: "GET",
					url: privateurl,
					headers:headers
				}
				request.get hitoptions, (error, response, body) ->
					console.log(body)
					jsonbody = JSON.parse(body)
					console.log(jsonbody)
					for i in [0...dbbot.configuration.length]
						dbbot.configuration[i].value = jsonbody.configuration[i].value
					if jsonbody.adapter=='slack'
						dbbot["slack"]="HUBOT_SLACK_TOKEN="+jsonbody.slack
						dbbot["hipchatId"]=''
						dbbot["hipchatPassword"]=''
						dbbot["Matter"]=''
						dbbot["MatterInURL"]=''
					else if jsonbody.adapter=='hipchat'
						dbbot["hipchatId"]=jsonbody.hipchatId
						dbbot["hipchatPassword"]=jsonbody.hipchatPassword
						dbbot["slack"]=''
						dbbot["Matter"]=''
						dbbot["MatterInURL"]=''
					else
						dbbot["Matter"]=jsonbody.Matter
						dbbot["MatterInURL"]=jsonbody.MatterInURL
						dbbot["slack"]=''
						dbbot["hipchatId"]=''
						dbbot["hipchatPassword"]=''
					mongodata = {
						url: process.env.ONBOTS_URL+"/newbot/"+botname,
						method: "PUT",
						headers: {"Content-type":"application/json"},
						body: dbbot,
						json: true
					}
					#updating user's bot data to mongodb
					request.put mongodata, (err, res, body) ->
						if body==undefined
							console.log err
							msg.send "Couldn't modify your changes in mongodb. Refer to hubot.log file for more details."
						else
							console.log(body)
							msg.send "Updated bot details successfully. Please restart the bot to apply the changes."
	
	robot.respond /restart (.*)/i, (msg) ->
		botname = msg.match[1]
		msg.send "Restarting "+botname+"...."
		botobj = {}
		dbbot = {}
		botopt = {
			url: process.env.ONBOTS_URL+"/newbot/"+botname,
			method: "GET"
		}
		#getting bot object from mongodb
		request.get botopt, (error, response, body) ->
			console.log body
			if body.indexOf('error')==-1
				dbbot = JSON.parse(body)
				#assigning values to botobject
				botobj["BotName"]=dbbot.BotName
				botobj["type"]=dbbot.bots
				botobj["repo"]=dbbot.repo
				botobj["adapter"]=dbbot.adapter
				botobj["BotDesc"]=dbbot.BotDesc
				botobj["BotType"]=dbbot.BotType
				botobj["vars"]=[]
				for i in [0...dbbot.configuration.length]
					botobj["vars"][i]=dbbot.configuration[i].bot_env+"="+dbbot.configuration[i].value
				if botobj["adapter"]=='slack'
					botobj["slack"]=dbbot.slack
					botobj["hipchatId"]=''
					botobj["hipchatPassword"]=''
					botobj["Matter"]=''
					botobj["MatterInURL"]=''
				else if botobj["adapter"]=='hipchat'
					botobj["hipchatId"]=dbbot.hipchatId
					botobj["hipchatPassword"]=dbbot.hipchatPassword
					botobj["slack"]=''
					botobj["Matter"]=''
					botobj["MatterInURL"]=''
				else
					botobj["Matter"]=dbbot.Matter
					botobj["MatterInURL"]=dbbot.MatterInURL
					botobj["slack"]=''
					botobj["hipchatId"]=''
					botobj["hipchatPassword"]=''
				if botobj["type"]=="User Defined Bot"
					botobj["addToExtJson"]=dbbot.addToExtJson
				opt = {
					url: process.env.ONBOTS_URL+"/restartbot",
					method: "POST",
					headers: {"Content-type":"application/json"},
					body: botobj,
					json: true
				}
				#restarting bot
				request.post opt, (err, res, body) ->
					console.log "err: "+err
					if body=="Error in Resarting Hubot"
						msg.send "There has been an error while deploying the bot. You may look at the logs for more details."
					else
						msg.send "The bot "+botobj.BotName+" has been redeployed successfully with your changes."
						deletescript = {
							url: process.env.ONBOTS_URL+"/deletefiles/restart"+botobj.BotName+".sh",
							method: "GET"
						}
						#deleting the restartscript created locally inside OnBots server
						request.get deletescript, (err, res, body) ->
							if res.body != 'successfully deleted'
								msg.send "**Warning**: Unable to delete the script file. Refer bot logs for details"
							console.log err
						dbbot["status"]='on'
						mongodata = {
							url: process.env.ONBOTS_URL+"/newbot/"+botname,
							method: "PUT",
							headers: {"Content-type":"application/json"},
							body: dbbot,
							json: true
						}
						#updatingbot status to mongodb
						request.put mongodata, (err, res, body) ->
							if body==undefined
								console.log err
								console.log "Couldn't modify bot status in mongodb. Refer to logs file for more details."
							else
								console.info "Updated bot status in db successfully."
			else
				msg.send body
