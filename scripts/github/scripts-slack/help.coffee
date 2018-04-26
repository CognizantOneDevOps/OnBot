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
# lists all commands that this bot can perform
#
#Configuration:
# HUBOT_NAME
#
#COMMANDS:
# help -> lists all the commands that the bot can perform
#
#Dependencies:
# "elasticSearch": "^0.9.2"

index = require('./index')

module.exports = (robot) ->
	robot.respond /.*help.*/, (msg) ->
		dt="Here are the list of commands I can perform for you:\n1)create repo <reponame> -> Create a repository\n2)create orgrepo <reponame> in <orgname> -> Create a repository inside an org\n3)list my repos -> List repository(ies)\n4)create branch <new_branch_name> in <reponame> from <existing_branch_name> -> Create a branch\n5)delete branch <branchname> from <reponame> -> Delete a branch\n6)invite <invitee_gituser_name> to <reponame> -> Invite a user(collaborators) to a github repo\n7)delete repo <reponame> -> Delete repository(ies)\n8)list collaborators of <reponame> -> list collaborators of a repo\n9)watch <reponame> -> Notify the user with commit Id and commit-author name whenever new commit occurs in the given repo\n10)stop watching <reponame> -> will stop watching the repo for commits\nP.S. preceed each command with @"+robot.name+" when you are in a channel/group\nSo what do you want me to do for you? :octopus:"
		msg.send dt
		setTimeout ( ->index.passData dt),1000
		
