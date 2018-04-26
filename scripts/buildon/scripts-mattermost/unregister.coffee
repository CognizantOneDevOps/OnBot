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

index = require('./index');
Datastore = require('../node_modules/nedb');
botname = process.env.HUBOT_NAME


module.exports = (robot) ->
	cmdunregister = new RegExp('@' + process.env.HUBOT_NAME + ' unregisterbuildon')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdunregister
		(msg) ->
			message = msg.match[0]
			username = {'name':msg.message.user.name};
			users = new Datastore({ filename: 'users-buildon.db', autoload: true });
			users.findOne username, (error, doc) ->
				if doc == null
					dt='Sorry, You are not registered.'
					msg.reply dt;
					setTimeout (->index.passData dt),1000
				else
					users.remove username, (error, doc) ->
						if error == null
							dt='Successfully unregistered from Build-on.'
							msg.reply dt
							setTimeout (->index.passData dt),1000
							actionmsg = 'Successfully unregistered from Build-on.'
							statusmsg = 'Success'
							index.wallData botname, message, actionmsg, statusmsg
						else
							dt='something went wrong.'
							msg.reply dt
							setTimeout (->index.passData dt),1000
	)
