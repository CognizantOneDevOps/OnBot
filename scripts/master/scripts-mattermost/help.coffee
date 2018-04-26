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

module.exports = (robot) ->
	cmd=new RegExp('@'+process.env.HUBOT_NAME+' help')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd
		(msg) ->
			msg.send "Here are the commands I can do for you:\n1)getDeployedBots -> get list of all deployed bots\n2)addBot <json_fileid> -> adds a bot with the given configuration in Json file\n3)getConfig Template <botname> -> get Json template for adding a particular type of bot\n4)delete <botname> -> delete the bot\n5)stop <botname> -> stop an active bot if it is running\n6)container status <botname> -> give the container status in which the bot is deployed\n7)getMetrics <botname> -> get system metrices for the given bot\n8)getHitmiss <botname> -> get hit-miss ratio of conversations of the given bot\n9)getLogs <botname> -> get deployment logs of the given bot\n10)getChatlog <botname> -> get chat logs of the given bot\n11)getBots -> get bots available in Bot Store\n12)getBotDetails <botname> -> get configuration and other details for a bot\n13)editBot <botname> <json_fileid> -> edit the bot configuration details in mongodb from the given json file\n14)restart <botname> -> restart the bot with the details stored in mongodb\n15)tail <number_of_lines> <botname> -> To download last <number_of_lines> of the logs of <botname>\n16)setWorkflowFile <botname> <fileid> -> update workflow.json file for given bot\n17)getWorkflowFile <botname> -> get the content of workflow.json file of given botP.S: preceed your command with @"+process.env.HUBOT_NAME+" :lion:"
	)
