request = require('request')
restart = require('./restart.js')
setwrkflow = require('./setwrkflow.js')

module.exports = (robot) ->
	robot.respond /getWorkflowFile (.*)/i, (msg) ->
		botname = msg.match[1]
		options = {
			url: process.env.ONBOTS_URL+"/getworkflowjson/workflow.json/"+botname,
			method: "GET"
		}
		request.get options, (error, response, body) ->
			if body.indexOf("Error from server")==-1
				msg.send "Here is the workflow.json content your bot is having:\n```"+body+"```"
			else
				msg.send body
	
	robot.respond /setWorkflowFile (.*) (.*)/i, (msg) ->
		botname = msg.match[1]
		filename = msg.match[2]
		msg.send "Your file will be copied and bot will be restarted soon. Please wait.."
		setwrkflow.setworkflow botname,filename, (err, response, body) ->
			if response=='copied'
				restart.restartbot botname, (error, body) ->
					if error==null
						msg.send body+" "+botname+" successfully"
					else
						msg.send error