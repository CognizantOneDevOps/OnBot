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

####
Configuration:

1. URELEASE_URL	
2. URELEASE_USER_ID
3. URELEASE_PASSWORD
4. HUBOT_NAME

Bot commands

1. delete release <release-name>
2. delete application <application-name>
3. delete user <user-name>
4. delete role <role-name>
5. delete initiative <initiative-name>
6. create role <role-name>
7. create release *no need to provide details. all details will come from release json file*
8. create initiative <application-name>
9. create user *no need to provide details. all details will come from user json file*
10.list users
11.list roles
12.list releases
13.list applications
14.list initiatives
15.start watching *It\'ll notify you if any application/release role/user/initiative is created by anybody*

Dependencies:

1. "elasticSearch": "^0.9.2"
2. "request": "2.81.0"

###
urelease_url = process.env.URELEASE_URL
urelease_user_id = process.env.URELEASE_USER_ID
urelease_password =  process.env.URELEASE_PASSWORD
botname = process.BOT_NAME || ''
pod_ip = process.env.MY_POD_IP || ''
request= require('request')

list_roles = require('./list_roles.js');
list_users = require('./list_users.js');
list_release = require('./list_release.js');
list_application = require('./list_application.js');
create_app = require('./create_app.js');
create_release = require('./create_release.js');
create_role = require('./create_role.js');
create_user = require('./create_user.js');
delete_user=require('./delete_user.js');
delete_application = require('./delete_application.js');
delete_release = require('./delete_release.js');
delete_role = require('./delete_role.js');
delete_initiatives = require('./delete_initiatives.js');
list_initiatives = require('./list_initiatives.js');
create_initiative = require('./create_initiative.js');

readjson = require './readjson.js'

uniqueId = (length=8) ->
  id = ""
  id += Math.random().toString(36).substr(2) while id.length < length
  id.substr 0, length



index = require('./index')
generate_id = require('./mongoConnt.coffee')

module.exports = (robot) ->
	robot.respond /help/i, (msg) ->

		msg.send 'delete release <release-name>';
		msg.send 'delete application <application-name>';
		msg.send 'delete user <user-name>';
		msg.send 'delete role <role-name>';
		msg.send 'delete initiative <initiative-name>';
		
		msg.send 'create role <role-name>';
		msg.send 'create release *no need to provide details. all details will come from release json file*';
		msg.send 'create application <application-name>';
		msg.send 'create initiative <application-name>';
		msg.send 'create user *no need to provide details. all details will come from user json file*';

		msg.send 'list users';
		msg.send 'list roles';
		msg.send 'list releases';
		msg.send 'list applications';
		msg.send 'list initiatives';
		msg.send 'start watching *It\'ll notify you if any application/release role/user/initiative is created by anybody* ';

		
	#list roles
	robot.respond /list roles/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.ureleaselistroles.workflowflag == true
				json={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleaselistroles.admin,podIp:pod_ip,message:msg.message.text};
				data = {text: 'Approve Request for list U-release components',attachments: [{text: '@',fallback: 'Yes or No?',callback_id: 'ureleaselistroles',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: JSON.stringify(json) },{ name: 'Reject', text: 'Reject',  type: 'button',  value: JSON.stringify(json),confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
				robot.messageRoom stdout.ureleaselistroles.adminid, data;
				msg.send 'Your approval request is waiting from '.concat(stdout.ureleaselistroles.admin);

			else
				list_roles.list_roles urelease_url, urelease_user_id, urelease_password, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
		

	#list users/i
	robot.respond /list users/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.ureleaselist_users.workflowflag == true
				json={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleaselist_users.admin,podIp:pod_ip,message:msg.message.text};
				data = {text: 'Approve Request for list U-release components',attachments: [{text: '@',fallback: 'Yes or No?',callback_id: 'ureleaselist_users',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: JSON.stringify(json) },{ name: 'Reject', text: 'Reject',  type: 'button',  value: JSON.stringify(json),confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
				robot.messageRoom stdout.ureleaselist_users.adminid, data;
				msg.send 'Your approval request is waiting from '.concat(stdout.ureleaselist_users.admin);

					
			else
				list_users.list_users urelease_url, urelease_user_id, urelease_password, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
		
	#list releases
	robot.respond /list releases/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.ureleaselist_release.workflowflag == true
				json={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleaselist_release.admin,podIp:pod_ip,message:msg.message.text};
				data = {text: 'Approve Request for list U-release components',attachments: [{text: '@',fallback: 'Yes or No?',callback_id: 'ureleaselist_release',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: JSON.stringify(json) },{ name: 'Reject', text: 'Reject',  type: 'button',  value: JSON.stringify(json),confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
				robot.messageRoom stdout.ureleaselist_release.adminid, data;
				msg.send 'Your approval request is waiting from '.concat(stdout.ureleaselist_release.admin);

					
			else
				list_release.list_release urelease_url, urelease_user_id, urelease_password, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
		
	#list applications/i
		
	robot.respond /list applications/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.ureleaselist_application.workflowflag == true
				json={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleaselist_application.admin,podIp:pod_ip,message:msg.message.text};
				data = {text: 'Approve Request for list U-release components',attachments: [{text: '@',fallback: 'Yes or No?',callback_id: 'ureleaselist_application',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: JSON.stringify(json) },{ name: 'Reject', text: 'Reject',  type: 'button',  value: JSON.stringify(json),confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
				robot.messageRoom stdout.ureleaselist_application.adminid, data;
				msg.send 'Your approval request is waiting from '.concat(stdout.ureleaselist_application.admin);

						
			else
				list_application.list_application urelease_url, urelease_user_id, urelease_password, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
						
		

	#create application (.*)/i, (msg)
		
	robot.respond /create application (.*)/i, (msg) ->
		app_anme = msg.match[1];
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.ureleasecreate_app.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={callback_id: 'ureleasecreate_app',botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleasecreate_app.admin,podIp:pod_ip,message:msg.message.text,tckid:tckid,app_anme:app_anme};
					data = {text: 'Approve Request for list U-release application create',attachments: [{text: '@'+payload.username+' requested to create application '+payload.app_anme+'\n',fallback: 'Yes or No?',callback_id: 'ureleasecreate_app',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: tckid },{ name: 'Reject', text: 'Reject',  type: 'button',  value: tckid,confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom stdout.ureleasecreate_app.adminid, data;
					msg.send 'Your approval request is waiting from '.concat(stdout.ureleasecreate_app.admin);

					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert					
					
			else
				create_app.create_app urelease_url, urelease_user_id, urelease_password, app_anme, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
						message=msg.match[0]
						actionmsg="U-release application created"
						statusmsg="Success"
						index.wallData botname, message, actionmsg, statusmsg;
						
					else
						msg.send error;
						setTimeout (->index.passData error),1000

	robot.router.post '/ureleasecreate_app', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			create_app.create_app urelease_url, urelease_user_id, urelease_password, data_http.app_anme, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
					setTimeout (->index.passData stdout),1000;
					message=data_http.message
					actionmsg="U-release application created"
					statusmsg="Success"
					index.wallData botname, message, actionmsg, statusmsg;
				else
					
					setTimeout (->index.passData error),1000;		
					robot.messageRoom data_http.userid, error;
		else
			robot.messageRoom data_http.userid, 'You are not authorized to create application.';


	#create user
	robot.respond /create user/i, (msg) ->
		app_name=msg.match[1];
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.ureleasecreate_user.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={callback_id: 'ureleasecreate_user',botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleasecreate_user.admin,podIp:pod_ip,message:msg.message.text,tckid:tckid};
					data = {text: 'Approve Request for list U-release user create',attachments: [{text: '@'+payload.username+' requested to create user \n',fallback: 'Yes or No?',callback_id: 'ureleasecreate_user',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: tckid },{ name: 'Reject', text: 'Reject',  type: 'button',  value: tckid,confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom stdout.ureleasecreate_user.adminid, data;
					msg.send 'Your approval request is waiting from '.concat(stdout.ureleasecreate_user.admin);
					
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				create_user.create_user urelease_url, urelease_user_id, urelease_password, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000;
						message=msg.match[0]
						actionmsg="U-release user created"
						statusmsg="Success"
						index.wallData botname, message, actionmsg, statusmsg;
					else
						msg.send error;
						setTimeout (->index.passData error),1000;
						
						
	robot.router.post '/ureleasecreate_user', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			create_user.create_user urelease_url, urelease_user_id, urelease_password, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
					setTimeout (->index.passData stdout),1000;
					message=data_http.message
					actionmsg="U-release user created"
					statusmsg="Success"
					index.wallData botname, message, actionmsg, statusmsg;
				else
					robot.messageRoom data_http.userid, error;
					setTimeout (->index.passData error),1000;
		else
			robot.messageRoom data_http.userid, 'You are not authorized create user.';
			
	#create release
	robot.respond /create release/i, (msg) ->
		app_anme = msg.match[1];
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.ureleasecreate_release.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={callback_id: 'ureleasecreate_release',botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleasecreate_release.admin,podIp:pod_ip,message:msg.message.text,tckid:tckid};
					data = {text: 'Approve Request for list U-release release create',attachments: [{text: '@'+payload.username+' requested to create release \n',fallback: 'Yes or No?',callback_id: 'ureleasecreate_release',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: tckid },{ name: 'Reject', text: 'Reject',  type: 'button',  value: tckid,confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom stdout.ureleasecreate_release.adminid, data;
					msg.send 'Your approval request is waiting from '.concat(stdout.ureleasecreate_release.admin);
					
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
					
					
			else
				create_release.create_release urelease_url, urelease_user_id, urelease_password, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000;
						message=msg.match[0]
						actionmsg="U-release release created"
						statusmsg="Success"
						index.wallData botname, message, actionmsg, statusmsg;
					else
						msg.send error;
						setTimeout (->index.passData error),1000;
						
	robot.router.post '/ureleasecreate_release', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			create_release.create_release urelease_url, urelease_user_id, urelease_password, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
					setTimeout (->index.passData stdout),1000;
					message=data_http.message
					actionmsg="U-release release created"
					statusmsg="Success"
					index.wallData botname, message, actionmsg, statusmsg;
				else
					robot.messageRoom data_http.userid, error;
					setTimeout (->index.passData error),1000;
		else
			robot.messageRoom data_http.userid, 'You are not authorized create release.';
		
	#create role
	robot.respond /create role (.*)/i, (msg) ->
		role_name = msg.match[1];
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.ureleasecreate_role.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={callback_id: 'ureleasecreate_role',botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleasecreate_role.admin,podIp:pod_ip,message:msg.message.text,tckid:tckid,role_name:role_name};
					data = {text: 'Approve Request for list U-release role create',attachments: [{text: '@'+payload.username+' requested to create role '+payload.role_name+'\n',fallback: 'Yes or No?',callback_id: 'ureleasecreate_role',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: tckid },{ name: 'Reject', text: 'Reject',  type: 'button',  value: tckid,confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom stdout.ureleasecreate_role.adminid, data;
					msg.send 'Your approval request is waiting from '.concat(stdout.ureleasecreate_role.admin);

					
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
					
			else
				create_role.create_role urelease_url, urelease_user_id, urelease_password, role_name, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000;
						message=msg.match[0]
						actionmsg="U-release role created"
						statusmsg="Success"
						index.wallData botname, message, actionmsg, statusmsg;
					else
						msg.send error;
						setTimeout (->index.passData error),1000;
	robot.router.post '/ureleasecreate_role', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			create_role.create_role urelease_url, urelease_user_id, urelease_password, data_http.role_name, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
					setTimeout (->index.passData stdout),1000;
					message=data_http.message
					actionmsg="U-release role created"
					statusmsg="Success"
					index.wallData botname, message, actionmsg, statusmsg;
				else
					robot.messageRoom data_http.userid, error;
					setTimeout (->index.passData error),1000;
		else
			robot.messageRoom data_http.userid, 'You are not authorized to create role.';
			
	#delete application	
	robot.respond /delete application (.*)/i, (msg) ->
		app_name = msg.match[1];
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.ureleasedelete_application.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={callback_id: 'ureleasedelete_application',botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleasedelete_application.admin,podIp:pod_ip,message:msg.message.text,tckid:tckid,app_name:app_name};
					data = {text: 'Approve Request for list U-release application delete',attachments: [{text: '@'+payload.username+' requested to delete application '+payload.app_name+'\n',fallback: 'Yes or No?',callback_id: 'ureleasedelete_application',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: tckid },{ name: 'Reject', text: 'Reject',  type: 'button', value: tckid,confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom stdout.ureleasedelete_application.adminid, data;
					msg.send 'Your approval request is waiting from '.concat(stdout.ureleasedelete_application.admin);

					
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
					
			else
				delete_application.delete_application urelease_url, urelease_user_id, urelease_password, app_name, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000;
						message=msg.match[0]
						actionmsg="U-release application deleted"
						statusmsg="Success"
						index.wallData botname, message, actionmsg, statusmsg;
					else
						msg.send error;
						setTimeout (->index.passData error),1000;
	robot.router.post '/ureleasedelete_application', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			delete_application.delete_application urelease_url, urelease_user_id, urelease_password, data_http.app_name, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
					setTimeout (->index.passData stdout),1000;
					message=data_http.message
					actionmsg="U-release application deleted"
					statusmsg="Success"
					index.wallData botname, message, actionmsg, statusmsg;
				else
					robot.messageRoom data_http.userid, error;
					setTimeout (->index.passData error),1000;
		else
			robot.messageRoom data_http.userid, 'You are not authorized to delete application.';
			
	#delete user
	robot.respond /delete user (.*)/i, (msg) ->
		app_name = msg.match[1];
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.ureleasedelete_user.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={callback_id: 'ureleasedelete_user',botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleasedelete_user.admin,podIp:pod_ip,message:msg.message.text,tckid:tckid,app_name:app_name};
					data = {text: 'Approve Request for list U-release user delete',attachments: [{text: '@'+payload.username+' requested to delete user '+payload.app_name+'\n',fallback: 'Yes or No?',callback_id: 'ureleasedelete_user',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: tckid },{ name: 'Reject', text: 'Reject',  type: 'button', value: tckid,confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom stdout.ureleasedelete_user.adminid, data;
					msg.send 'Your approval request is waiting from '.concat(stdout.ureleasedelete_user.admin);
					
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				delete_user.delete_user urelease_url, urelease_user_id, urelease_password, app_name, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000;
						message=msg.match[0]
						actionmsg="U-release user deleted"
						statusmsg="Success"
						index.wallData botname, message, actionmsg, statusmsg;
					else
						msg.send error;
						setTimeout (->index.passData error),1000;
	robot.router.post '/ureleasedelete_user', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			delete_user.delete_user urelease_url, urelease_user_id, urelease_password, data_http.app_name, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
					setTimeout (->index.passData stdout),1000;
					message=data_http.message
					actionmsg="U-release user deleted"
					statusmsg="Success"
					index.wallData botname, message, actionmsg, statusmsg;
				else
					robot.messageRoom data_http.userid, error;
					setTimeout (->index.passData error),1000;
		else
			robot.messageRoom data_http.userid, 'You are not authorized to delete user.';
						
	#delete role
	robot.respond /delete role (.*)/i, (msg) ->
		app_name = msg.match[1];
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.ureleasedelete_role.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={callback_id: 'ureleasedelete_role',botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleasedelete_role.admin,podIp:pod_ip,message:msg.message.text,tckid:tckid,app_name:app_name};
					data = {text: 'Approve Request for list U-release role delete',attachments: [{text: '@'+payload.username+' requested to delete role '+payload.app_name+'\n',fallback: 'Yes or No?',callback_id: 'ureleasedelete_role',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: tckid },{ name: 'Reject', text: 'Reject',  type: 'button',  value: tckid,confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom stdout.ureleasedelete_role.adminid, data;
					msg.send 'Your approval request is waiting from '.concat(stdout.ureleasedelete_role.admin);
					
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
					
					
			else
				delete_role.delete_role urelease_url, urelease_user_id, urelease_password, app_name, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000;
						message=msg.match[0]
						actionmsg="U-release role deleted"
						statusmsg="Success"
						index.wallData botname, message, actionmsg, statusmsg;
					else
						msg.send error;
						setTimeout (->index.passData error),1000;
						
	robot.router.post '/ureleasedelete_role', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			delete_role.delete_role urelease_url, urelease_user_id, urelease_password, data_http.app_name, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
					message=data_http.message
					actionmsg="U-release role deleted"
					statusmsg="Success"
					index.wallData botname, message, actionmsg, statusmsg;
					setTimeout (->index.passData stdout),1000;
				else
					robot.messageRoom data_http.userid, error;
					setTimeout (->index.passData error),1000;
		else
			robot.messageRoom data_http.userid, 'You are not authorized to delete role.';
			
	#delete release
	robot.respond /delete release (.*)/i, (msg) ->
		app_name = msg.match[1];
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.ureleasedelete_release.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={callback_id: 'ureleasedelete_release',botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleasedelete_release.admin,podIp:pod_ip,message:msg.message.text,tckid:tckid,app_name:app_name};
					data = {text: 'Approve Request for list U-release release delete',attachments: [{text: '@'+payload.username+' requested to delete release '+payload.app_name+'\n',fallback: 'Yes or No?',callback_id: 'ureleasedelete_release',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: tckid },{ name: 'Reject', text: 'Reject',  type: 'button',  value: tckid,confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom stdout.ureleasedelete_release.adminid, data;
					msg.send 'Your approval request is waiting from '.concat(stdout.ureleasedelete_release.admin);
					
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
					
			else
				delete_release.delete_release urelease_url, urelease_user_id, urelease_password, app_name, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000;
						message=msg.match[0]
						actionmsg="U-release release deleted"
						statusmsg="Success"
						index.wallData botname, message, actionmsg, statusmsg;
					else
						msg.send error;
						setTimeout (->index.passData error),1000;
	robot.router.post '/ureleasedelete_release', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			delete_release.delete_release urelease_url, urelease_user_id, urelease_password, data_http.app_name, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
					message=data_http.message
					actionmsg="U-release release deleted"
					statusmsg="Success"
					index.wallData botname, message, actionmsg, statusmsg;
					setTimeout (->index.passData stdout),1000;
				else
					
								
					robot.messageRoom data_http.userid, error;
					setTimeout (->index.passData error),1000;
		else
			robot.messageRoom data_http.userid, 'You are not authorized to delete release.';
			
			
			
	#delete initiative
	robot.respond /delete initiative (.*)/i, (msg) ->
		role_name = msg.match[1];
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.ureleasedelete_initiatives.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={callback_id: 'ureleasedelete_initiatives',botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleasedelete_initiatives.admin,podIp:pod_ip,message:msg.message.text,tckid:tckid,role_name:role_name};
					data = {text: 'Approve Request for delete initiative',attachments: [{text: '@'+payload.username+' to delete initiative',fallback: 'Yes or No?',callback_id: 'ureleasedelete_initiatives',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: tckid },{ name: 'Reject', text: 'Reject',  type: 'button',  value: tckid,confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom stdout.ureleasedelete_initiatives.adminid, data;
					msg.send 'Your approval request is waiting from '.concat(stdout.ureleasedelete_initiatives.admin);

					
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
					
			else
				delete_initiatives.delete_initiatives urelease_url, urelease_user_id, urelease_password, role_name, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000;
						message=msg.match[0]
						actionmsg="U-release initiative deleted"
						statusmsg="Success"
						index.wallData botname, message, actionmsg, statusmsg;
					else
						msg.send error;
						setTimeout (->index.passData error),1000;
						
						
	robot.router.post '/ureleasedelete_initiatives', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			delete_initiatives.delete_initiatives urelease_url, urelease_user_id, urelease_password, data_http.role_name, (error, stdout, stderr) ->
				if error == "null"
					msg.send stdout;
					setTimeout (->index.passData stdout),1000;
					message=data_http.message
					actionmsg="U-release initiative deleted"
					statusmsg="Success"
					index.wallData botname, message, actionmsg, statusmsg;
				else
					robot.messageRoom data_http.userid, error;
					setTimeout (->index.passData error),1000;
		else
			robot.messageRoom data_http.userid, 'You are not authorized to delete initiative.';
			
	#create initiative
	robot.respond /create initiative (.*)/i, (msg) ->
		app_anme = msg.match[1];
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.ureleasecreate_initiative.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={callback_id: 'ureleasecreate_initiative',botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleasecreate_initiative.admin,podIp:pod_ip,message:msg.message.text,tckid:tckid,app_anme:app_anme};
					data = {text: 'Approve Request for create initiative',attachments: [{text: '@'+payload.username+' to create initiative',fallback: 'Yes or No?',callback_id: 'ureleasecreate_initiative',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: tckid },{ name: 'Reject', text: 'Reject',  type: 'button',  value: tckid,confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom stdout.ureleasecreate_initiative.adminid, data;
					msg.send 'Your approval request is waiting from '.concat(stdout.ureleasecreate_initiative.admin);
					
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
					
			else
				create_initiative.create_initiative urelease_url, urelease_user_id, urelease_password, app_anme, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						message=msg.match[0]
						actionmsg="U-release initiative created"
						statusmsg="Success"
						index.wallData botname, message, actionmsg, statusmsg;
						setTimeout (->index.passData stdout),1000;
					else
						msg.send error;
						setTimeout (->index.passData error),1000;
	robot.router.post '/ureleasecreate_initiative', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			create_initiative.create_initiative urelease_url, urelease_user_id, urelease_password, data_http.app_anme, (error, stdout, stderr) ->
				if error == "null"
					msg.send stdout;
					setTimeout (->index.passData stdout),1000;
					message=data_http.message
					actionmsg="U-release initiative created"
					statusmsg="Success"
					index.wallData botname, message, actionmsg, statusmsg;
				else
					
					robot.messageRoom data_http.userid, error;
					setTimeout (->index.passData error),1000;
		else
			robot.messageRoom data_http.userid, 'You are not authorized to create initiative.';
			
			
	#list initiative
	robot.respond /list initiatives/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.ureleaselist_initiatives.workflowflag == true
				json={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleaselist_initiatives.admin,podIp:pod_ip,message:msg.message.text};
				data = {text: 'Approve Request for',attachments: [{text: '@',fallback: 'Yes or No?',callback_id: 'ureleaselist_initiatives',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: JSON.stringify(json) },{ name: 'Reject', text: 'Reject',  type: 'button',  value: JSON.stringify(json),confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
				robot.messageRoom stdout.ureleaselist_initiatives.adminid, data;
				msg.send 'Your approval request is waiting from '.concat(stdout.ureleaselist_initiatives.admin);
					
			else
				list_initiatives.list_initiatives urelease_url, urelease_user_id, urelease_password, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000;
					else
						msg.send error;
						setTimeout (->index.passData error),1000;
