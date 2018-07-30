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
		dt="Here are the list of commands I can perform for you:\n1)start <jobname> build with params <param1> <param2>... -> Build the given job with given params\n2)delete job <jobname> -> delete the given job from jenkins\n3)create job <jobname> with <config_file_name_with_extension> -> create a jenkins job with given config file\n4)install <plugin1> <plugin2>... in jenkins -> install the given plugins in jenkins\n5)restart jenkins -> do a restart for jenkins\n6)jenkins list -> list all available jenkins jobs\n7)jenkins build <jobname> -> build the given job\n8)getAllInstance -> get details of all jenkins instance (applicable only for enterprise slack)\n9)setInstance <instance_name> -> set jenkins instance with which the bot will work(applicable only for enterprise slack)\nP.S. preceed each command with @"+process.env.HUBOT_NAME+" when you are in a channel/group\nSo what do you want me to do for you? :nerd_face:"
		msg.send dt
		setTimeout ( ->index.passData dt),1000
