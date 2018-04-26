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
# creates and deletes branches inside a github repository
#
#Configuration:
# HUBOT_NAME
# HUBOT_GITHUB_API
# HUBOT_GITHUB_USER
# HUBOT_GITHUB_TOKEN
#
#COMMANDS:
# watch repo <reponame> -> start watching for commits in <reponame>
# stop watching <reponame> -> stop watching for commits in <reponame>
#
#Dependencies:
# gitnotification.js
# nedb: "1.8.0"

git_notify = require('./gitnotification.js');
index = require('./index')
Datastore = require('../node_modules/nedb');
clearid = ''

check_flag = 0;
module.exports = (robot) ->
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match /watch repo (.*)/i
		(msg) ->
			users = new Datastore({ filename: 'users-github.db', autoload: true });
			uname = {'name':msg.message.user.name};
			users.findOne uname, (error, doc) ->
				if doc == null
					git_repo = msg.match[1];
					flag = 0;
					clear_id = 0;
					msg.reply 'Started watching '+git_repo+' for you.';
					run_status = () ->
						git_notify.git_notify git_repo, flag, clear_id, (coffee_error, coffee_stdout, coffee_stderr) ->
							if coffee_error == null
								msg.reply coffee_stdout
								setTimeout (->index.passData coffee_stdout),1000
							else
								msg.reply coffee_error
								setTimeout (->index.passData coffee_error),1000
					intervalId = setInterval(run_status, 5000)
					clearid = intervalId
					userdata = {'reponame':git_repo, 'name':msg.message.user.name}
					users.insert userdata, (error, doc) ->
						console.log(error);
						console.log ('Inserted');
						console.log(doc);
					check_flag = 1;
				else
					msg.reply 'You are already watching something. One repository at a time :-)'
	)
	
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match /stop watching (.*)/i
		(msg) ->
			users = new Datastore({ filename: 'users-github.db', autoload: true });
			uname = {'name':msg.message.user.name};
			users.findOne uname, (error, doc) ->
				if doc == null
					msg.reply 'You are not watching anything.'
				else
					if check_flag == 1
						clearTimeout clearid;
						dt='Not watching repo '+doc.reponame+' anymore';
						msg.reply dt
						setTimeout (->index.passData dt),1000
						check_flag = 0;
						userdata = {'name':msg.message.user.name};
						users.remove userdata, (error, doc) ->
							console.log('deleted from db');
					check_flag = 0;
	)
