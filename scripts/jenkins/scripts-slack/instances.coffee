#-------------------------------------------------------------------------------
# Copyright 2018 Cognizant Technology Solutions
#   
#   Licensed under the Apache License, Version 2.0 (the "License"); you may not
#   use this file except in compliance with the License.  You may obtain a copy
#   of the License at
#   
#     http://www.apache.org/licenses/LICENSE-2.0
#   
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
#   License for the specific language governing permissions and limitations under
#   the License.
#-------------------------------------------------------------------------------

#Description:
# Manages multiple jenkins instance with single bot
# Compatible with Slack Enterprise edition
#
#Configuration:
# HUBOT_JENKINS_URL
# HUBOT_JENKINS_USER
# HUBOT_JENKINS_PASSWORD
#
#COMMANDS:
#getAllInstance -> fetch all available jenkins instance details from mongodb
#setInstance <instancename> -> set the mentioned instance as the jenkins instance with which the bot should work
#
#Dependencies:
# "elasticSearch": "^0.9.2"
# "request": "2.81.0"

request = require('request')
fs=require('fs')
index = require('./index')
mongoconnector = require('./mongoConnt')


module.exports = (robot) ->
	robot.respond /getAllInstance/i, (res) ->
		console.log res.message.user.id
		if res.message.rawMessage.channel._modelName == 'Channel'
			res.send "Sorry! Can't display instance details in channel. Please try DM."
		else
			mongoconnector.getInstance res.message.user.id, (err, doc) ->
				if err != null
					res.send err
					res.send doc
				else
					instances = '*Instance Name*\t\t\t*URL*'
					for i in [0...doc.length]
						instances += '\n' + doc[i].instancename + "\t\t\t" + doc[i].url
					res.send instances
	
	robot.respond /setInstance (.*)/i, (res) ->
		if res.message.rawMessage.channel._modelName == 'Channel'
			res.send "Sorry! This operation is not permitted in channel. Please try DM."
		else
			instancename = res.match[1]
			mongoconnector.setInstance instancename,res.message.user.id, (err,doc) ->
				if err
					res.send err
					res.send doc
				else
					process.env['HUBOT_JENKINS_URL'] = doc.url
					process.env['HUBOT_JENKINS_PASSWORD'] = doc.password
					process.env['HUBOT_JENKINS_USER'] = doc.user
					if doc.token
						process.env['HUBOT_JENKINS_API_TOKEN'] = doc.token
						process.env['HUBOT_JENKINS_VERSION'] = doc.version
					res.send "Success! I will work for " + doc.instancename
