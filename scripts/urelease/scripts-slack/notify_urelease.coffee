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

notify = require('./notify.js');
urelease_url = process.env.URELEASE_URL
urelease_user_id = process.env.URELEASE_USER_ID
urelease_password =  process.env.URELEASE_PASSWORD


module.exports = (robot) ->
	robot.respond /start watching/i, (msg) ->
		msg.send 'Started watching Urelease for you. I will keep you informed.';
		val = ['application', 'release', 'initiative', 'users', 'roles'];
		for scale in [0..val.length-1]
			console.log(val[scale]);
			notify.notify urelease_url, urelease_user_id, urelease_password, val[scale], (error, stdout, stderr) ->
				if error == "null"
					msg.send stdout;
				else
					msg.send error;
