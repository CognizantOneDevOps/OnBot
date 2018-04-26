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

request= require('request')

module.exports = (robot) ->
	cmdlistaudit = new RegExp('@'+process.env.HUBOT_NAME+' getChatlog (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdlistaudit
		(msg) ->
			botname=msg.match[1];
			msg.send "Click the url to download the log file\n"+process.env.ONBOTS_URL+"/downloadchat/"+botname;
	)
