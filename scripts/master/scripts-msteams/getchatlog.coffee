request= require('request') # Requiring npm require package

module.exports = (robot) ->
	robot.respond /getChatlog (.*)/i, (msg) ->
		botname=msg.match[1];
		msg.send "Click the url to download the log file\n"+process.env.ONBOTS_URL+"/downloadchat/"+botname;