#Description:
# OneDevOps-OnBots download hubot logs functionality implementation for hubot
#
#Configurations:
# ONBOTS_URL: your OneDevOps-OnBots server url
#
#Commands:
# @botname get logs of <botname> -> gives the link to download the log of the given bot as a <botname>.log file in clientside
#

fs = require('fs') # Requiring npm file-system package

request = require('request') # Requiring npm request package

module.exports = (robot) ->
	robot.respond /getLogs (.*)/i, (msg) ->
		botname = msg.match[1]
		msg.send "Click [here]("+process.env.ONBOTS_URL+"/download/"+botname+"/all) to download the log file"
	
	robot.respond /tail (.*) (.*)/i, (msg) ->
		nol = msg.match[1]
		botname = msg.match[2]
		options = {
			url: process.env.ONBOTS_URL+"/download/"+botname+"/"+nol,
			method: "GET"
		}
		request.get options, (error, response, body) ->
			msg.send "Fetching logs of "+botname+"..."
			msg.send "`"+response.body+"`"
	
	robot.respond /attachment/i, (msg) ->
		console.log msg