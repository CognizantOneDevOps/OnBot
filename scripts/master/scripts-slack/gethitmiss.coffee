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

masterbot_hitmiss = require('./hitmiss_analytics.js') # Importing js file in masterbot_hitmiss

module.exports = (robot) ->
	robot.respond /getHitmiss (.*)/i, (msg) ->
		first = msg.match[1]
		console.log first
		str = ''
		masterbot_hitmiss.masterbot_hitmiss first,(error, stdout, stderr) ->
			if stdout
				str += ':small_blue_diamond:' + ' HITMISS RATIO : ' + ((stdout.hitmiss/stdout.totalconv) * 100).toFixed() + '%\n' # Calculating HitMiss Ratio
				str += ':small_blue_diamond:' + ' TOTAL_CONVERSATIONS : ' + stdout.totalconv # total conversations with the bot
				msg.send str;
			else if stderr
				msg.send stderr;
			else if error
				msg.send error;
