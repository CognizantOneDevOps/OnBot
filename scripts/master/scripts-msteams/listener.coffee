fs = require('fs') # Requiring npm file-system package
request = require('request') # Requiring npm request package
getallbots = require('./getallbots.js') # Importing javascript file as getallbots
addbots = require('./addbots.js')
getdetailbot = require('./getdetails.js')
deletebot = require('./deletebot.js')
stopbot = require('./stop.js')
constatus = require('./containerstatus.js')
module.exports = (robot) ->
	
	robot.respond /getDeployedBots/i, (msg) ->
		getallbots.getallbots (error, stdout, stderr) ->
			if(stdout)
				msg.send(stdout)
			if(stderr)
				msg.send(stderr)
	
	robot.respond /addBot (.*)/i, (msg) ->
		filename=msg.match[1]
		msg.send "Bot is getting Deployed....\n You will be notified when deployment is done"
		addbots.addbots filename , (error, stdout, stderr) ->
			if(stdout)
				msg.send(stdout)
			if(stderr)
				msg.send(stderr)
	
	robot.respond /getConfig Template (.*)/i, (msg) ->
		botype = msg.match[1]
		getdetailbot.getdetailbot botype,(error, stdout, stderr) ->
			if(stdout)
				msg.send '`'+stdout+'`'
			if(stderr)
				msg.send(stderr)
	
	robot.respond /delete (.*)/i, (msg) ->
		botname = msg.match[1]
		msg.send botname+" Deletion is Started...."
		deletebot.deletebot botname, (error, stdout, stderr) ->
			if(stdout)
				msg.send(stdout)
			if(stderr)
				msg.send(stderr)
	
	robot.respond /stop (.*)/i, (msg) ->
		botname = msg.match[1]
		msg.send "Stopping "+botname+" ..."
		stopbot.stopbot botname,(error, stdout, stderr) ->
			if(stdout)
				msg.send(stdout)
			if(stderr)
				msg.send(stderr)
	
	robot.respond /container status (.*)/i, (msg) ->
		botname = msg.match[1]
		msg.send "Fetching container status for "+botname
		constatus.constatus botname,(error, stdout, stderr) ->
			if(stdout)
				msg.send(stdout)
			if(stderr)
				msg.send(stderr)