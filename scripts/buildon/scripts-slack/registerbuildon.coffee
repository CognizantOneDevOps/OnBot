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

Datastore = require('../node_modules/nedb');

module.exports = (robot) ->
	robot.respond /registerbuildon (.*)/i, (msg) ->
		role_name = msg.match[1].toLowerCase()
		users = new Datastore({ filename: 'users-buildon.db', autoload: true });
		user = {'name':msg.message.user.name};
		
		users.findOne user, (error, doc) ->
			if doc == null
				user = {'username':role_name, 'name':msg.message.user.name};
				users.insert user, (error, doc) ->
					msg.reply "You are registerted in Bot successfully";
			else
				msg.reply 'You are already registered'
