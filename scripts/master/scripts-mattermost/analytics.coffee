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
	analytics = new RegExp('@'+process.env.HUBOT_NAME+' getMetrics (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match analytics
		(msg) ->
			first = msg.match[1]
			masterbot.masterbot first,(error, stdout, stderr) ->
				
				if stdout
					str = ''
					str += '|' + 'Parameter' + '|' + 'Value' + '|' + '\n' + '| :------------ |:---------------:| -----:|' + '\n';
					for key of stdout
						if(key!='timestamp' && key!='Botname')
							if(key=='Total_memeory')
								str += '|' + 'Total_memory' + '|' + (parseFloat((stdout[key]/ Math.pow(1000, Math.floor(Math.log(stdout[key]) / Math.log(1000)))).toFixed(4)) + " " + "GB") + '|' + '\n' # Calculating total memory in GB.
							else if(key=='uptime')
								str += '|' + key + '|' + (Math.floor(stdout[key]/ 60 / 60 / 24) + ' Days ' + (Math.floor(stdout[key]/ 60 / 60)) % 24 + ' Hours ' + (Math.floor(stdout[key]/ 60)) % 60 + ' Minutes ' + ((stdout[key]) % 60).toFixed(0) + ' Seconds') + '|' # Calculating uptime in days,hours,minutes and seconds.
							else if(key=='rss')
								str += '|' + key + '|' + (parseFloat((stdout[key]/ Math.pow(1024000, Math.floor(Math.log(stdout[key]) / Math.log(1024000)))).toFixed(4)) + " " + "MB") + '|' + '\n' # Calculating rss in MB.
							else
								str += '|' + key + '|' + (parseFloat((stdout[key]/ Math.pow(1000, Math.floor(Math.log(stdout[key]) / Math.log(1000)))).toFixed(4)) + " " + "GB") + '|' + '\n' # Calculating memory in GB.
					msg.send str
				else if stderr
					msg.send stderr;
				else if error
					msg.send error;
	)
