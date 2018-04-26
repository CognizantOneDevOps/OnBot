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
botname = process.HUBOT_NAME || ''
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
delete_application = require('./delete_application.js');
delete_release = require('./delete_release.js');
delete_role = require('./delete_role.js');
delete_user=require('./delete_user.js');
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
	cmdhelp = new RegExp('@' + process.env.HUBOT_NAME + ' help')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdhelp
		(msg) ->
			msg.send 'delete release <release-name> \n delete application <application-name> \n delete user <user-name> \n delete role <role-name> \n delete initiative <initiative-name> \n create role <role-name> \n create release *no need to provide details. all details will come from release json file* \n create application <application-name> \n create initiative <application-name> \n create user *no need to provide details. all details will come from user json file* \n list users \n list roles \n list releases \n list applications \n list initiatives \n start watching *It\'ll notify you if any application/release role/user/initiative is created by anybody* ';
	)
	cmdlistroles = new RegExp('@' + process.env.HUBOT_NAME + ' list roles')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdlistroles
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.ureleaselistroles.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleaselistroles.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'ureleaselistroles',tckid:tckid};
						data = {"channel": stdout.ureleaselistroles.admin,"text":"Approve Request for list roles in U-release components","message":"Approve Request for list roles in U-release components",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'ureleaselistroles',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url":process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.ureleaselistroles.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				else
					list_roles.list_roles urelease_url, urelease_user_id, urelease_password, (error, stdout, stderr) ->
						if error == "null"
							msg.send stdout;
							setTimeout (->index.passData stdout),1000
						else
							msg.send error;
							setTimeout (->index.passData error),1000
	)
	cmdlistusers = new RegExp('@' + process.env.HUBOT_NAME + ' list users')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdlistusers
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.ureleaselist_users.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleaselist_users.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'ureleaselist_users',tckid:tckid};
						data = {"channel": stdout.ureleaselist_users.admin,"text":"Approve Request for list user in U-release components","message":"Approve Request for list users U-release components",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'ureleaselist_users',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.ureleaselist_users.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				else
					list_users.list_users urelease_url, urelease_user_id, urelease_password, (error, stdout, stderr) ->
						if error == "null"
							msg.send stdout;
							setTimeout (->index.passData stdout),1000
						else
							msg.send error;
							setTimeout (->index.passData error),1000
	)
	cmdlistrelease = new RegExp('@' + process.env.HUBOT_NAME + ' list release')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdlistrelease
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.ureleaselist_release.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleaselist_release.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'ureleaselist_release',tckid:tckid};
						data = {"channel": stdout.ureleaselist_release.admin,"text":"Approve Request for list release in U-release components","message":"Approve Request for list release in U-release components",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'ureleaselist_release',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.ureleaselist_release.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				else
					list_release.list_release urelease_url, urelease_user_id, urelease_password, (error, stdout, stderr) ->
						if error == "null"
							msg.send stdout;
							setTimeout (->index.passData stdout),1000
						else
							msg.send error;
							setTimeout (->index.passData error),1000
	)
	cmdlistapp = new RegExp('@' + process.env.HUBOT_NAME + ' list applications')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdlistapp
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.ureleaselist_application.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleaselist_application.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'ureleaselist_application',tckid:tckid};
						data = {"channel": stdout.ureleaselist_application.admin,"text":"Approve Request for list applications U-release components","message":"Approve Request for list applications in U-release components",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'ureleaselist_application',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.ureleaselist_application.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				else
					list_application.list_application urelease_url, urelease_user_id, urelease_password, (error, stdout, stderr) ->
						if error == "null"
							msg.send stdout;
							setTimeout (->index.passData stdout),1000
						else
							msg.send error;
							setTimeout (->index.passData error),1000
	)
	cmdcreateapp = new RegExp('@' + process.env.HUBOT_NAME + ' create application (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreateapp
		(msg) ->
			app_anme = msg.match[1];
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.ureleasecreate_app.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleasecreate_app.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,app_anme:app_anme,callback_id: 'ureleasecreate_app',tckid:tckid};
						data = {"channel": stdout.ureleasecreate_app.admin,"text":"Approve Request for create application in U-release components","message":"Approve Request for create application in U-release components",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'ureleasecreate_app',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.ureleasecreate_app.admin);
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
	)
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
			
	cmdcreateuser = new RegExp('@' + process.env.HUBOT_NAME + ' create user')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreateuser
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.ureleasecreate_user.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleasecreate_user.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'ureleasecreate_user',tckid:tckid};
						data = {"channel": stdout.ureleasecreate_user.admin,"text":"Approve Request for create user in U-release components","message":"Approve Request for create user in U-release components",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'ureleasecreate_user',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.ureleasecreate_user.admin);
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
	)
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
	
	cmdcreatrelease = new RegExp('@' + process.env.HUBOT_NAME + ' create release')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreatrelease
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.ureleasecreate_release.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleasecreate_release.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'ureleasecreate_release',tckid:tckid};
						data = {"channel": stdout.ureleasecreate_release.admin,"text":"Approve Request for create release in U-release components","message":"Approve Request for create release in U-release components",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'ureleasecreate_release',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.ureleasecreate_release.admin);
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
	)
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
	
	cmdcreaterole = new RegExp('@' + process.env.HUBOT_NAME + ' create role (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreaterole
		(msg) ->
			role_name = msg.match[1];
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.ureleasecreate_role.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleasecreate_role.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,role_name:role_name,callback_id: 'ureleasecreate_role',tckid:tckid};
						data = {"channel": stdout.ureleasecreate_role.admin,"text":"Approve Request for create role in U-release components","message":"Approve Request for create role in U-release components",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'ureleasecreate_role',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.ureleasecreate_role.admin);
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
							index.wallData botname, message, actionmsg,statusmsg;
						else
							msg.send error;
							setTimeout (->index.passData error),1000;
	)
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
	
	cmddeleteapp = new RegExp('@' + process.env.HUBOT_NAME + ' delete application (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddeleteapp
		(msg) ->
			app_name = msg.match[1];
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.ureleasedelete_application.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleasedelete_application.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,app_name:app_name,callback_id: 'ureleasedelete_application',tckid:tckid};
						data = {"channel": stdout.ureleasedelete_application.admin,"text":"Approve Request for delete application in U-release components","message":"Approve Request for delete application in U-release components",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'ureleasedelete_application',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.ureleasedelete_application.admin);
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
	)
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
	
	cmddeleteuser = new RegExp('@' + process.env.HUBOT_NAME + ' delete user (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddeleteuser
		(msg) ->
			app_name = msg.match[1];
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.ureleasedelete_user.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleasedelete_user.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,app_name:app_name,callback_id: 'ureleasedelete_user',tckid:tckid};
						data = {"channel": stdout.ureleasedelete_user.admin,"text":"Approve Request for delete user in U-release components","message":"Approve Request for delete user in U-release components",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'ureleasedelete_user',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.ureleasedelete_user.admin);
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
								
	)
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
	
	
	cmddeleterelease = new RegExp('@' + process.env.HUBOT_NAME + ' delete release (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddeleterelease
		(msg) ->
			app_name = msg.match[1];
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.ureleasedelete_release.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleasedelete_release.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,app_name:app_name,callback_id: 'ureleasedelete_release',tckid:tckid};
						data = {"channel": stdout.ureleasedelete_release.admin,"text":"Approve Request for delete release in U-release components","message":"Approve Request for delete release in U-release components",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'ureleasedelete_release',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.ureleasedelete_release.admin);
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
	)
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
	
	cmddeleteerole = new RegExp('@' + process.env.HUBOT_NAME + ' delete role (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddeleteerole
		(msg) ->
			app_name = msg.match[1];
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.ureleasedelete_role.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleasedelete_role.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,app_name:app_name,callback_id: 'ureleasedelete_role',tckid:tckid};
						data = {"channel": stdout.ureleasedelete_role.admin,"text":"Approve Request for delete role in U-release components","message":"Approve Request for delete role in U-release components",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'ureleasedelete_role',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.ureleasedelete_role.admin);
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
	)
	robot.router.post '/ureleasedelete_role', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			delete_role.delete_role urelease_url, urelease_user_id, urelease_password, data_http.app_name, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
					setTimeout (->index.passData stdout),1000;
					message=data_http.message
					actionmsg="U-release role deleted"
					statusmsg="Success"
					index.wallData botname, message, actionmsg, statusmsg;
				else
					robot.messageRoom data_http.userid, error;
					setTimeout (->index.passData error),1000;
		else
			robot.messageRoom data_http.userid, 'You are not authorized to delete role.';
	
	cmddeleteeinitiative = new RegExp('@' + process.env.HUBOT_NAME + ' delete initiative (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddeleteeinitiative
		(msg) ->
			role_name = msg.match[1];
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.ureleasedelete_initiatives.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleasedelete_initiatives.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,role_name:role_name,callback_id: 'ureleasedelete_initiatives',tckid:tckid};
						data = {"channel": stdout.ureleasedelete_initiatives.admin,"text":"Approve Request for delete initiative in U-release components","message":"Approve Request for delete initiative in U-release components",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'ureleasedelete_initiatives',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.ureleasedelete_initiatives.admin);
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
	)
	robot.router.post '/ureleasedelete_initiatives', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			delete_initiatives.delete_initiatives urelease_url, urelease_user_id, urelease_password, data_http.role_name, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
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
	
	cmdcreateinitiative = new RegExp('@' + process.env.HUBOT_NAME + ' create initiative (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreateinitiative
		(msg) ->
			app_anme= msg.match[1];
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.ureleasecreate_initiative.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleasecreate_initiative.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,app_anme:app_anme,callback_id: 'ureleasecreate_initiative',tckid:tckid};
						data = {"channel": stdout.ureleasecreate_initiative.admin,"text":"Approve Request for create initiative in U-release components","message":"Approve Request for create initiative in U-release components",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'ureleasecreate_initiative',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.ureleasecreate_initiative.admin);
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
	)
	robot.router.post '/ureleasecreate_initiative', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			create_initiative.create_initiative urelease_url, urelease_user_id, urelease_password, data_http.app_anme, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
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
	
	cmdlistinitiative = new RegExp('@' + process.env.HUBOT_NAME + ' list initiatives')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdlistinitiative
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.ureleaselist_initiatives.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.ureleaselist_initiatives.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'ureleaselist_initiatives',tckid:tckid};
						data = {"channel": stdout.ureleaselist_initiatives.admin,"text":"Approve Request for list initiatives in U-release components","message":"Approve Request for list initiatives in U-release components",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'ureleaselist_initiatives',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.ureleaselist_initiatives.admin);
				else
					list_initiatives.list_initiatives urelease_url, urelease_user_id, urelease_password, (error, stdout, stderr) ->
						if error == "null"
							msg.send stdout;
							setTimeout (->index.passData stdout),1000;
						else
							msg.send error;
							setTimeout (->index.passData error),1000;
	)
