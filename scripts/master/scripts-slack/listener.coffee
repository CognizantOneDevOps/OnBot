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

fs = require('fs') # Requiring npm file-system package
request = require('request') # Requiring npm request package
getallbots = require('./getallbots.js') # Importing javascript file as getallbots
addbots = require('./addbots.js')
getdetailbot = require('./getdetails.js')
deletebot = require('./deletebot.js')
stopbot = require('./stop.js')
constatus = require('./containerstatus.js')
module.exports = (robot) ->
	
	robot.respond /getDeployedBots/i, (msg) ->
		getallbots.getallbots (error, stdout, stderr) ->
			if(stdout)
				msg.send(stdout)
			if(stderr)
				msg.send(stderr)
	
	robot.respond /addBot (.*)/i, (msg) ->
		filename=msg.match[1]
		msg.send "Bot is getting Deployed....\n You will be notified when deployment is done"
		addbots.addbots filename , (error, stdout, stderr) ->
			if(stdout)
				msg.send(stdout)
			if(stderr)
				msg.send(stderr)
	
	robot.respond /getConfig Template (.*)/i, (msg) ->
		botype = msg.match[1]
		getdetailbot.getdetailbot botype,(error, stdout, stderr) ->
			if(stdout)
				msg.send '```'+stdout+'```'
			if(stderr)
				msg.send(stderr)
	
	robot.respond /delete (.*)/i, (msg) ->
		msg.send botname+" Deletion is Started...."
		botname = msg.match[1]
		deletebot.deletebot botname, (error, stdout, stderr) ->
			if(stdout)
				msg.send(stdout)
			if(stderr)
				msg.send(stderr)
	
	robot.respond /stop (.*)/i, (msg) ->
		botname = msg.match[1]
		msg.send "Stopping "+botname+" ..."
		stopbot.stopbot botname,(error, stdout, stderr) ->
			if(stdout)
				msg.send(stdout)
			if(stderr)
				msg.send(stderr)
	
	robot.respond /container status (.*)/i, (msg) ->
		botname = msg.match[1]
		msg.send "Fetching container status for "+botname
		constatus.constatus botname,(error, stdout, stderr) ->
			if(stdout)
				msg.send(stdout)
			if(stderr)
				msg.send(stderr)
