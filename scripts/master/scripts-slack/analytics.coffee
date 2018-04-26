#-------------------------------------------------------------------------------
# Copyright 2018 Cognizant Technology Solutions
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License.  You may obtain a copy
# of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.
#-------------------------------------------------------------------------------

masterbot = require('./master_bot_analytics.js') # Importing js file as masterbot.
botname = process.env.HUBOT_NAME

module.exports = (robot) ->
	robot.respond /getMetrics (.*)/i, (msg) ->
		bot = msg.match[1]
		# Calling the alias of getanalytics function, masterbot
		masterbot.masterbot bot,(error, stdout, stderr) ->
			
			if stdout
				str = ''
				for key of stdout
					if(key!='timestamp' && key!='Botname')
						if(key=='Total_memeory')
							# Calculating total memory in GB
							str += ':small_blue_diamond:' + 'Total_memory' + ' : ' + (parseFloat((stdout[key]/ Math.pow(1000, Math.floor(Math.log(stdout[key]) / Math.log(1000)))).toFixed(4)) + " " + "GB") + '\n'
						else if(key=='uptime')
							# Calculating uptime in days,hours,minutes and seconds
							str += ':small_blue_diamond:' + key + ' : ' + (Math.floor(stdout[key]/ 60 / 60 / 24) + ' Days ' + (Math.floor(stdout[key]/ 60 / 60)) % 24 + ' Hours ' + (Math.floor(stdout[key]/ 60)) % 60 + ' Minutes ' + ((stdout[key]) % 60).toFixed(0) + ' Seconds')
						else if(key=='rss')
							# Calculating rss in MB
							str += ':small_blue_diamond:' + key + ' : ' + (parseFloat((stdout[key]/ Math.pow(1024000, Math.floor(Math.log(stdout[key]) / Math.log(1024000)))).toFixed(4)) + " " + "MB") + '\n'
						else
							# Calculating memory in GB
							str += ':small_blue_diamond:' + key + ' : ' + (parseFloat((stdout[key]/ Math.pow(1000, Math.floor(Math.log(stdout[key]) / Math.log(1000)))).toFixed(4)) + " " + "GB") + '\n'
				msg.send str
			else if stderr
				msg.send stderr;
			else if error
				msg.send error;
