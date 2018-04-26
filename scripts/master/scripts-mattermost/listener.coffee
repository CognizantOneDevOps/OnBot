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

fs = require('fs')
request = require('request')
getallbots = require('./getallbots.js')
addbots = require('./addbots.js')
getdetailbot = require('./getdetails.js')
deletebot = require('./deletebot.js')
stopbot = require('./stop.js')
constatus = require('./containerstatus.js')
module.exports = (robot) ->
	
	cmdgetDeployedBots = new RegExp('@'+process.env.HUBOT_NAME+' getDeployedBots')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdgetDeployedBots
		(msg) ->
			getallbots.getallbots (error, stdout, stderr) ->
				if(stdout)
					msg.send(stdout)
				if(stderr)
					msg.send(stderr)
	)
	
	cmdaddBot = new RegExp('@'+process.env.HUBOT_NAME+' addBot (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdaddBot
		(msg) ->
			fileid = msg.match[1]
			msg.send "Bot is getting Deployed....\n You will be notified when deployment is done"
			addbots.addbots fileid,(error, stdout, stderr) ->
				
				if(stdout)
					msg.send(stdout)
				if(stderr)
					msg.send(stderr)
	)
	
	cmdgetConfigTemplate = new RegExp('@'+process.env.HUBOT_NAME+' getConfig Template (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdgetConfigTemplate
		(msg) ->
			botype = msg.match[1]
			getdetailbot.getdetailbot botype,(error, stdout, stderr) ->
				if(stdout)
					msg.send(stdout)
				if(stderr)
					msg.send(stderr)
	)
	
	cmddelete = new RegExp('@'+process.env.HUBOT_NAME+' delete (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddelete
		(msg) ->
			botname = msg.match[1]
			msg.send botname+" Deletion is Started...."
			deletebot.deletebot botname, (error, stdout, stderr) ->
				if(stdout)
					msg.send(stdout)
				if(stderr)
					msg.send(stderr)
	)
	cmdstop = new RegExp('@'+process.env.HUBOT_NAME+' stop (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdstop
		(msg) ->
			
			botname = msg.match[1]
			msg.send "Stopping "+botname+" ..."
			stopbot.stopbot botname,(error, stdout, stderr) ->
				if(stdout)
					msg.send(stdout)
				if(stderr)
					msg.send(stderr)
	)
	cmdcontainerstat = new RegExp('@'+process.env.HUBOT_NAME+' container status (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcontainerstat
		(msg) ->
			botname = msg.match[1]
			msg.send "Fetching container status for "+botname
			constatus.constatus botname,(error, stdout, stderr) ->
				if(stdout)
					msg.send(stdout)
				if(stderr)
					msg.send(stderr)
	)
