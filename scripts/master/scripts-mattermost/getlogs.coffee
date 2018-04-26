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

#Description:
# OneDevOps-OnBots download hubot logs functionality implementation for hubot
#
#Configurations:
# ONBOTS_URL: your OneDevOps-OnBots server url
#
#Commands:
# @botname get logs of <botname> -> gives the link to download the log of the given bot as a <botname>.log file in clientside
#

fs = require('fs')
request = require('request')

module.exports = (robot) ->
	cmdgetlog = new RegExp('@' + process.env.HUBOT_NAME + ' getLogs (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdgetlog
		(msg) ->
			botname = msg.match[1]
			msg.send "[Click here]("+process.env.ONBOTS_URL+"/download/"+botname+"/all) to download the log file"
	)
	cmdtaillog = new RegExp('@' + process.env.HUBOT_NAME + ' tail (.*) (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdtaillog
		(msg) ->
			nol = msg.match[1]
			botname = msg.match[2]
			options = {
				url: process.env.ONBOTS_URL+"/download/"+botname+"/"+nol,
				method: "GET"
			}
			request.get options, (error, response, body) ->
				msg.send "Fetching logs of "+botname+"..."
				msg.send "``` \n"+response.body+"```"
	)
