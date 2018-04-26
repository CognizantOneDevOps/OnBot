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

udeploy_notify = require('./udeploy_notify.js');
udeploy_url = process.env.UDEPLOY_URL
udeploy_user_id = process.env.UDEPLOY_USER_ID
udeploy_password =  process.env.UDEPLOY_PASSWORD


module.exports = (robot) ->
	robot.respond /start watching/i, (msg) ->
		msg.send 'Started watching Urelease for you. I\'ll keep you informed.';
		val = ['resource', 'component', 'application'];
		for scale in [0..val.length-1]
			console.log(val[scale]);
			udeploy_notify.udeploy_notify udeploy_url, udeploy_user_id, udeploy_password, val[scale], (error, stdout, stderr) ->
				if error == "null"
					msg.send stdout;
				else
					msg.send error;
