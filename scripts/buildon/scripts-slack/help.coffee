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
# replies the user with a list of available commands that the bot can perform
#
#Configuration:
# HUBOT_NAME
#
#COMMANDS:
# help -> gives the list of commands this bot can perform
#
#Dependencies:
# "elasticSearch": "^0.9.2"

index = require('./index')

module.exports = (robot) ->
	robot.respond /.*help.*/, (msg) ->
		dt="Here are the list of commands I can perform for you:\n1)registerbuildon <username> -> register into buildon with username\n2)startbuildon <username> <jobname> <branchname> -> start a build of the given branch of the given jobname\n3)checkstatus <commitid> -> check the status of a buildon commitid (which is triggered by buildon bot)\n4)unregisterbuildon -> unregister from buildon\nP.S. preceed each command with @"+process.env.HUBOT_NAME+" when you are in a channel/group\nSo what do you want me to do for you? :b:"
		msg.send dt
		setTimeout ( ->index.passData dt),1000
