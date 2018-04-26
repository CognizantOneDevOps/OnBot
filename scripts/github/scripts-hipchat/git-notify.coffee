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

git_notify = require('./gitnotification.js');
index = require('./index')
Datastore = require('../node_modules/nedb');
clearid = ''

check_flag = 0;
module.exports = (robot) ->
	robot.respond /watch repo (.*)/i, (msg) ->
		users = new Datastore({ filename: 'users-github.db', autoload: true });
		scott = {'name':msg.message.user.name};
		users.findOne scott, (error, doc) ->
			if doc == null
				git_repo = msg.match[1];
				flag = 0;
				clear_id = 0;
				msg.reply 'Started watching '+git_repo+' for you.';
				run_status = () ->
					git_notify.git_notify git_repo, flag, clear_id, (coffee_error, coffee_stdout, coffee_stderr) ->
						if coffee_error == null
							msg.reply coffee_stdout;
							setTimeout (->index.passData coffee_stdout),1000
						else
				intervalId = setInterval(run_status, 5000);#1000 = 1 sec
				clearid = intervalId
				scott_1 = {'reponame':git_repo, 'name':msg.message.user.name};
				users.insert scott_1, (error, doc) ->
					console.log(error);
					console.log ('Inserted');
					console.log(doc);
					#console.log(clearid);
					
				check_flag = 1;
			else
				msg.reply 'You are already watching something. One repository at a time :-)'

		robot.respond /stop watching (.*)/i, (msg) ->
			users = new Datastore({ filename: 'users-github.db', autoload: true });
			scott = {'name':msg.message.user.name};
			users.findOne scott, (error, doc) ->
				if doc == null
					msg.reply 'You are not watching anything.'
				else
					if check_flag == 1
						clearTimeout clearid;
						dt='Not watching repo '+doc.reponame+' anymore';
						msg.reply dt
						setTimeout (->index.passData dt),1000
						check_flag = 0;
						scott_del = {'name':msg.message.user.name};
						users.remove scott_del, (error, doc) ->
							console.log('deleted from db');
					check_flag = 0;
