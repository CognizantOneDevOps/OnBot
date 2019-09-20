masterbot_hitmiss = require('./hitmiss_analytics.js') # Importing js file in masterbot_hitmiss

module.exports = (robot) ->
	robot.respond /getHitmiss (.*)/i, (msg) ->
		first = msg.match[1]
		console.log first
		str = ''
		masterbot_hitmiss.masterbot_hitmiss first,(error, stdout, stderr) ->
			if stdout
				str += '* HITMISS RATIO : ' + ((stdout.hitmiss/stdout.totalconv) * 100).toFixed() + '%\n' # Calculating HitMiss Ratio
				str += '* TOTAL_CONVERSATIONS : ' + stdout.totalconv # total conversations with the bot
				msg.send str;
			else if stderr
				msg.send stderr;
			else if error
				msg.send error;