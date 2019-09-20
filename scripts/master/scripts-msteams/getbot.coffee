get_bot_name = require('./getbots.js'); # Importing javascript file in get_bot_name variable
index = require('./index.js')

module.exports = (robot) ->
	robot.respond /getBots/i, (msg) ->
		get_bot_name.get_bots (error, stdout, stderr) ->
			if error == "null"
				msg.send stdout;
				setTimeout (->index.passData stdout),1000
			else
				msg.send error;
				setTimeout (->index.passData error),1000