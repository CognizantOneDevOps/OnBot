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

###
Coffee script used for:
Manipulating farms
Viewing farms,scripts,servers,role.

Set of bot commands
1. print scalr farms
2. print scalr scripts
3. print scalr server <farm-id>
4. print scalr role <farm-id>
5. print scalr farm <farm-id>
6. create farm <farm-name>
7. execute script <script-id> in server <server-id>
8. launch farm <farm-id>
9. delete farm <farm-id>
10. resume farm <farm-id>
11. suspend farm <farm-id>
12. terminate farm <farm-id>
13. clone farm <farm-id> to <new-farm-name>
14. create role <role-name> in <farm-id> on <os-name( either windows or ubuntu )>\n

Env to set:
1. SCALR_API_URL
2. SCALR_ACCESS_ID
3. SCALR_ACCESS_KEY
4. SCALR_ENV_ID

Dependencies:
1. request
###
eindex = require('./index')

scalr_url = process.env.SCALR_API_URL
scalr_access_id = process.env.SCALR_ACCESS_ID
scalr_access_key =  process.env.SCALR_ACCESS_KEY
env_id = process.env.SCALR_ENV_ID
botname = process.env.HUBOT_NAME
pod_ip = process.env.MY_POD_IP
generate_id = require('./mongoConnt')
request=require('request')
scalr_func = require('./scalr_func.js');
scalr_func_farmname = require('./scalr_func_farmname.js');
farm_create = require('./farm_create.js');
farm_delete = require('./farm_delete.js');
script_execute = require('./script_execute.js');
farm_list = require('./farm_list.js');
script_list = require('./script_list.js');
server_list = require('./server_list.js');
role_list = require('./role_list.js');
farm_search = require('./farm_search.js');
farm_launch = require('./farm_launch.js');
farm_resume = require('./farm_resume.js');
farm_suspend = require('./farm_suspend.js');
farm_terminate = require('./farm_terminate.js');
farm_clone = require('./farm_clone.js');
role_create = require('./role_create.js');
readjson = require './readjson.js'

module.exports = (robot) ->
	cmd=new RegExp('@' + process.env.HUBOT_NAME + ' help')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd
		(msg) ->
			msg.send 'print scalr farms\nprint scalr scripts\nprint scalr server <farm-id>\nprint scalr role <farm-id>\nprint scalr farm <farm-id>\ncreate farm <farm-name>\nexecute script <script-id> in server <server-id>\nlaunch farm <farm-id>\ndelete farm <farm-id>\nresume farm <farm-id>\nsuspend farm <farm-id>\nterminate farm <farm-id>\nclone farm <farm-id> to <new-farm-name>\ncreate role <role-name> in <farm-id> on <os-name( either windows or ubuntu )>\n**** NO SPECIAL CHARACTER IS ACCEPTED BY SCALR ****';
	)	
	
	#print scalr farms	
	cmd_print_farms=new RegExp('@' + process.env.HUBOT_NAME + ' print scalr farms')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_print_farms
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.printscalrfarm.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.printscalrfarm.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'printscalrfarm',tckid:tckid};
						data = {"channel": stdout.printscalrfarm.admin,"text":"Request from"+payload.username+"Approve Request for print scalr farms","message":"Approve Request for print scalr farms",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'printscalrfarm',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.printscalrfarm.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				else
					farm_list.farm_list scalr_url, scalr_access_id, scalr_access_key, env_id, (coffee_error, coffee_stdout, coffee_stderr) ->
						if coffee_error == null
							msg.send coffee_stdout
						else
							msg.reply coffee_error;
	)

	robot.router.post '/printscalrfarm', (request, response) ->
		data_http   = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			farm_list.farm_list scalr_url, scalr_access_id, scalr_access_key, env_id, (coffee_error, coffee_stdout, coffee_stderr) ->
				if coffee_error == null
					robot.messageRoom data_http.userid, coffee_stdout;
				else
					robot.messageRoom data_http.userid, coffee_error;
		else
			robot.messageRoom data_http.userid,'Sorry, You are not authorized.'
	
	#print scalr scripts
	cmd_print_scripts=new RegExp('@' + process.env.HUBOT_NAME + ' print scalr scripts')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_print_scripts
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.printscalrscripts.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.printscalrscripts.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'printscalrscripts',tckid:tckid};
						data = {"channel": stdout.printscalrscripts.admin,"text":"Request from"+payload.username+"Approve Request for print scalr scripts","message":"Approve Request for print scalr scripts",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'printscalrscripts',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.printscalrscripts.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				else
					script_list.script_list scalr_url, scalr_access_id, scalr_access_key, env_id, (coffee_error, coffee_stdout, coffee_stderr) ->
						if coffee_error == null
							msg.send coffee_stdout
						else
							msg.reply coffee_error;
	)
	
	robot.router.post '/printscalrscripts', (request, response) ->
		data_http   = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			script_list.script_list scalr_url, scalr_access_id, scalr_access_key, env_id, (coffee_error, coffee_stdout, coffee_stderr) ->
				if coffee_error == null
					robot.messageRoom data_http.userid, coffee_stdout;
				else
					robot.messageRoom data_http.userid, coffee_error;
		else
			robot.messageRoom data_http.userid,'Sorry, You are not authorized.'

	#print scalr server
	cmd_print_server=new RegExp('@' + process.env.HUBOT_NAME + ' print scalr server (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_print_server
		(msg) ->
			farm_id = msg.match[1];
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.printscalrserver.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,farm_id:farm_id,username:msg.message.user.name,userid:msg.message.room,approver:stdout.printscalrserver.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'printscalrserver',tckid:tckid};
						data = {"channel": stdout.printscalrserver.admin,"text":"Request from"+payload.username+"Approve Request for print scalr server","message":"Approve Request for print scalr server",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'printscalrserver',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.printscalrserver.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				else
					server_list.server_list scalr_url, scalr_access_id, scalr_access_key, env_id, farm_id, (coffee_error, coffee_stdout, coffee_stderr) ->
						if coffee_error == null
							msg.send coffee_stdout
						else
							msg.reply coffee_error;
	)

	robot.router.post '/printscalrserver', (request, response) ->
		data_http   = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			server_list.server_list scalr_url, scalr_access_id, scalr_access_key, env_id, data_http.farm_id, (coffee_error, coffee_stdout, coffee_stderr) ->
				if coffee_error == null
					robot.messageRoom data_http.userid, coffee_stdout;
				else
					robot.messageRoom data_http.userid, coffee_error;			
		else
			robot.messageRoom data_http.userid,'Sorry, You are not authorized.'
		
	#print scalr role 
	cmd_print_role=new RegExp('@' + process.env.HUBOT_NAME + ' print scalr role (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_print_role
		(msg) ->
			farm_id = msg.match[1];
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.printscalrroles.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,farm_id:farm_id,username:msg.message.user.name,userid:msg.message.room,approver:stdout.printscalrroles.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'printscalrroles',tckid:tckid};
						data = {"channel": stdout.printscalrroles.admin,"text":"Request from"+payload.username+"Approve Request for print scalr role","message":"Approve Request for print scalr role",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'printscalrroles',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.printscalrroles.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				else 
					role_list.role_list scalr_url, scalr_access_id, scalr_access_key, env_id, farm_id, (coffee_error, coffee_stdout, coffee_stderr) ->
						if coffee_error == null
							msg.send coffee_stdout
						else
							msg.reply coffee_error;
	)
	
	robot.router.post '/printscalrroles', (request, response) ->
		data_http   = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			role_list.role_list scalr_url, scalr_access_id, scalr_access_key, env_id, data_http.farm_id, (coffee_error, coffee_stdout, coffee_stderr) ->
				if coffee_error == null
					robot.messageRoom data_http.userid, coffee_stdout;
				else
					robot.messageRoom data_http.userid, coffee_error;			
		else
			robot.messageRoom data_http.userid,'Sorry, You are not authorized.'

	#print scalr farm		
	cmd_print_farm=new RegExp('@' + process.env.HUBOT_NAME + ' print scalr farm (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_print_farm
		(msg) ->
			farm_name = msg.match[1];
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.printscalrspecificfarm.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,farm_name:farm_name,username:msg.message.user.name,userid:msg.message.room,approver:stdout.printscalrspecificfarm.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'printscalrspecificfarm',tckid:tckid};
						data = {"channel": stdout.printscalrspecificfarm.admin,"text":"Request from"+payload.username+"Approve Request for print scalr farm","message":"Approve Request for print scalr farm",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'printscalrspecificfarm',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.printscalrspecificfarm.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				else 
					farm_search.farm_search scalr_url, scalr_access_id, scalr_access_key, env_id, farm_name, (coffee_error, coffee_stdout, coffee_stderr) ->
						if coffee_error == null
							msg.send coffee_stdout
						else
							msg.reply coffee_error;
	)
				
	robot.router.post '/printscalrspecificfarm', (request, response) ->
		data_http   = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			farm_search.farm_search scalr_url, scalr_access_id, scalr_access_key, env_id, data_http.farm_name, (coffee_error, coffee_stdout, coffee_stderr) ->
				if coffee_error == null
					robot.messageRoom data_http.userid, coffee_stdout;
				else
					robot.messageRoom data_http.userid, coffee_error;
		else
			robot.messageRoom data_http.userid,'Sorry, You are not authorized.'	
					
	#execute script
	cmd_execute_script=new RegExp('@' + process.env.HUBOT_NAME + ' execute script (.*) in server (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_execute_script
		(msg) ->
			script_id = msg.match[1]
			server_id = msg.match[2];
			message = 'execute script '+script_id+'in server '+server_id;
			actionmsg = 'Script executed in Scalr Farm';
			statusmsg = 'Success';
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.executescriptinfarm.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,script_id:script_id,server_id:server_id,username:msg.message.user.name,userid:msg.message.room,approver:stdout.executescriptinfarm.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'executescriptinfarm',tckid:tckid};
						data = {"channel": stdout.executescriptinfarm.admin,"text":"Request from"+payload.username+"Approve Request for execute script","message":"Approve Request for execute script",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'executescriptinfarm',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.executescriptinfarm.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				else 
					script_execute.script_execute scalr_url, scalr_access_id, scalr_access_key, env_id, script_id, server_id, (coffee_error, coffee_stdout, coffee_stderr) ->
						if coffee_error == null
							msg.send 'Script executed with ID : '.concat(coffee_stdout);
							eindex.wallData botname, message, actionmsg, statusmsg;
						else
							msg.reply coffee_error;
	)
				
	robot.router.post '/executescriptinfarm', (request, response) ->
		data_http   = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			script_execute.script_execute scalr_url, scalr_access_id, scalr_access_key, env_id, data_http.script_id, data_http.server_id, (coffee_error, coffee_stdout, coffee_stderr) ->
				if coffee_error == null
					robot.messageRoom data_http.userid, 'Script executed with ID : '.concat(coffee_stdout);
					eindex.wallData botname, message, actionmsg, statusmsg;
				else 
					robot.messageRoom data_http.userid, coffee_error;
		else
			robot.messageRoom data_http.userid,'Sorry, You are not authorized.'	
								
	#create farm					
	cmd_create_farm=new RegExp('@' + process.env.HUBOT_NAME + ' create farm (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_create_farm
		(msg) ->
			farm_name = msg.match[1]
			message = 'create farm '+farm_name;
			actionmsg = 'Scalr farm created';
			statusmsg = 'Success';
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.createscalrfarm.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,farm_name:farm_name,username:msg.message.user.name,userid:msg.message.room,approver:stdout.createscalrfarm.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'createscalrfarm',tckid:tckid};
						data = {"channel": stdout.createscalrfarm.admin,"text":"Request from"+payload.username+"Approve Request for create farm","message":"Approve Request for create farm",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'createscalrfarm',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {	
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.createscalrfarm.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				else	
					farm_create.farm_create scalr_url, scalr_access_id, scalr_access_key, env_id, farm_name, (coffee_error, coffee_stdout, coffee_stderr) ->
						if coffee_error == null
							msg.send 'Farm created with ID : '.concat(coffee_stdout);
							eindex.wallData botname, message, actionmsg, statusmsg;
						else
							msg.reply coffee_error;
	)
					
	robot.router.post '/createscalrfarm', (request, response) ->
		data_http   = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			farm_create.farm_create scalr_url, scalr_access_id, scalr_access_key, env_id, data_http.farm_name, (coffee_error, coffee_stdout, coffee_stderr) ->
				if coffee_error == null
					robot.messageRoom data_http.userid, 'Farm created with ID : '.concat(coffee_stdout);
					eindex.wallData botname, message, actionmsg, statusmsg;
				else
					robot.messageRoom data_http.userid, coffee_error;
		else
			robot.messageRoom data_http.userid,'Sorry, You are not authorized.'			
				
	#create role 
	cmd_create_role=new RegExp('@' + process.env.HUBOT_NAME + ' create role (.*) in (.*) on (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_create_role
		(msg) ->
			farm_name = msg.match[2]
			role_name = msg.match[1]
			os_name = msg.match[3]
			message = 'create role '+role_name+'in '+farm_name+'on '+os_name;
			actionmsg = 'Role created in scalr farm';
			statusmsg = 'Success';
			os_name = os_name.toLowerCase();
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.createscalrroleinfarm.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,farm_name:farm_name,role_name:role_name,os_name:os_name,username:msg.message.user.name,userid:msg.message.room,approver:stdout.createscalrroleinfarm.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'createscalrroleinfarm',tckid:tckid};
						data = {"channel": stdout.createscalrroleinfarm.admin,"text":"Request from"+payload.username+"Approve Request for create role","message":"Approve Request for create role",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'createscalrroleinfarm',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.createscalrroleinfarm.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				else	
					role_create.role_create scalr_url, scalr_access_id, scalr_access_key, env_id, farm_name, role_name, os_name, (coffee_error, coffee_stdout, coffee_stderr) ->
						if coffee_error == null
							msg.send 'Role created with ID : '.concat(coffee_stdout);
							eindex.wallData botname, message, actionmsg, statusmsg;
						else
							msg.reply coffee_error;
	)
				
	robot.router.post '/createscalrroleinfarm', (request, response) ->
		data_http   = if request.body.payload? then JSON.parse request.body.payload else request.body						
		if data_http.action == 'Approve'					
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);		
			role_create.role_create scalr_url, scalr_access_id, scalr_access_key, env_id, data_http.farm_name, data_http.role_name, data_http.os_name, (coffee_error, coffee_stdout, coffee_stderr) ->
				if coffee_error == null
					robot.messageRoom data_http.userid, 'Role created with ID : '.concat(coffee_stdout);
					eindex.wallData botname, message, actionmsg, statusmsg;
								
				else
				robot.messageRoom data_http.userid, coffee_error;
		else
			robot.messageRoom data_http.userid,'Sorry, You are not authorized.'	
					
	#delete farm
	cmd_delete_farm=new RegExp('@' + process.env.HUBOT_NAME + ' delete farm (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_delete_farm
		(msg) ->
			farm_name = msg.match[1]
			message= 'delete farm '+farm_name;
			actionmsg = 'Farm deleted in Scalr';
			statusmsg = 'Success';
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.deletescalrfarm.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,farm_name:farm_name,username:msg.message.user.name,userid:msg.message.room,approver:stdout.deletescalrfarm.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'deletescalrfarm',tckid:tckid};
						data = {"channel": stdout.deletescalrfarm.admin,"text":"Request from"+payload.username+"Approve Request for delete farm","message":"Approve Request for delete farm",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'deletescalrfarm',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.deletescalrfarm.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				else	
					farm_delete.farm_delete scalr_url, scalr_access_id, scalr_access_key, env_id, farm_name, (coffee_error, coffee_stdout, coffee_stderr) ->
						if coffee_error == null
							msg.send 'Farm deleted : '.concat(farm_name);
							eindex.wallData botname, message, actionmsg, statusmsg;
						else
							msg.reply coffee_error;
	)
				
	robot.router.post '/deletescalrfarm', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			farm_delete.farm_delete scalr_url, scalr_access_id, scalr_access_key, env_id, data_http.farm_name, (coffee_error, coffee_stdout, coffee_stderr) ->
				if coffee_error == null
					robot.messageRoom data_http.userid, 'Farm deleted with ID : '.concat(data_http.farm_name);
					eindex.wallData botname, message, actionmsg, statusmsg;
				else
					robot.messageRoom data_http.userid, coffee_error;
		else
			robot.messageRoom data_http.userid,'Sorry, You are not authorized.'	
	
	#launch farm 
	cmd_launch_farm=new RegExp('@' + process.env.HUBOT_NAME + ' launch farm (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_launch_farm
		(msg) ->
			farm_id = msg.match[1]
			message = 'launch farm '+farm_id;
			actionmsg = 'Farm launched in Scalr';
			statusmsg = 'Success';
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.launchscalrfarm.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,farm_id:farm_id,username:msg.message.user.name,userid:msg.message.room,approver:stdout.launchscalrfarm.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'launchscalrfarm',tckid:tckid};
						data = {"channel": stdout.launchscalrfarm.admin,"text":"Request from"+payload.username+"Approve Request for launch farm","message":"Approve Request for launch farm",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'launchscalrfarm',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.launchscalrfarm.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				else	
					farm_launch.farm_launch scalr_url, scalr_access_id, scalr_access_key, env_id, farm_id, (coffee_error, coffee_stdout, coffee_stderr) ->
						if coffee_error == null
							msg.send 'Farm launched with ID'.concat(farm_id);
							eindex.wallData botname, message, actionmsg, statusmsg;
						else
							msg.reply coffee_error;
	)
	
	
	robot.router.post '/launchscalrfarm', (request, response) ->
		data_http   = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			farm_launch.farm_launch scalr_url, scalr_access_id, scalr_access_key, env_id, data_http.farm_id, (coffee_error, coffee_stdout, coffee_stderr) ->
				if coffee_error == null
					robot.messageRoom data_http.userid, 'Farm launched with ID'.concat(data_http.farm_id);
					eindex.wallData botname, message, actionmsg, statusmsg;
				else
					robot.messageRoom data_http.userid, coffee_error;
		else
			robot.messageRoom data_http.userid,'Sorry, You are not authorized.'	
					
	#resume farm				
	cmd_resume_farm=new RegExp('@' + process.env.HUBOT_NAME + ' resume farm (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_resume_farm
		(msg) ->
			farm_id = msg.match[1]
			message = 'resume farm '+farm_id;
			actionmsg = 'Farm resumed in Scalr';
			statusmsg = 'Success';
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.resumescalrfarm.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,farm_id:farm_id,username:msg.message.user.name,userid:msg.message.room,approver:stdout.resumescalrfarm.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'resumescalrfarm',tckid:tckid};
						data = {"channel": stdout.resumescalrfarm.admin,"text":"Request from"+payload.username+"Approve Request for resume farm","message":"Approve Request for resume farm",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'resumescalrfarm',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.resumescalrfarm.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				else 
					farm_resume.farm_resume scalr_url, scalr_access_id, scalr_access_key, env_id, farm_id, (coffee_error, coffee_stdout, coffee_stderr) ->
						if coffee_error == null
							msg.send 'Farm resumed with ID'.concat(farm_id);
							eindex.wallData botname, message, actionmsg, statusmsg;
						else
							msg.reply coffee_error;
	)
				
	robot.router.post '/resumescalrfarm', (request, response) ->
		data_http   = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			farm_resume.farm_resume scalr_url, scalr_access_id, scalr_access_key, env_id, data_http.farm_id, (coffee_error, coffee_stdout, coffee_stderr) ->
				if coffee_error == null
					robot.messageRoom data_http.userid, 'Farm resumed with ID'.concat(data_http.farm_id);
					eindex.wallData botname, message, actionmsg, statusmsg;
				else
					robot.messageRoom data_http.userid, coffee_error;
		else
			robot.messageRoom data_http.userid,'Sorry, You are not authorized.'
					
	#suspend farm		
	cmd_suspend_farm=new RegExp('@' + process.env.HUBOT_NAME + ' suspend farm (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_suspend_farm
		(msg) ->
			farm_id = msg.match[1]
			message = 'suspend farm '+farm_id;
			actionmsg = 'Farm suspended in Scalr';
			statusmsg = 'Success';
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.suspendscalrfarm.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,farm_id:farm_id,username:msg.message.user.name,userid:msg.message.room,approver:stdout.suspendscalrfarm.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'suspendscalrfarm',tckid:tckid};
						data = {"channel": stdout.suspendscalrfarm.admin,"text":"Request from"+payload.username+"Approve Request for suspend farm","message":"Approve Request for suspend farm",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'suspendscalrfarm',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.suspendscalrfarm.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				else
					farm_suspend.farm_suspend scalr_url, scalr_access_id, scalr_access_key, env_id, farm_id, (coffee_error, coffee_stdout, coffee_stderr) ->
						if coffee_error == null
							msg.send 'Farm suspended with ID'.concat(farm_id);
							eindex.wallData botname, message, actionmsg, statusmsg;
						else
							msg.reply coffee_error;
	)
				
	robot.router.post '/suspendscalrfarm', (request, response) ->
		data_http   = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			farm_suspend.farm_suspend scalr_url, scalr_access_id, scalr_access_key, env_id, data_http.farm_id, (coffee_error, coffee_stdout, coffee_stderr) ->
				if coffee_error == null
					robot.messageRoom data_http.userid, 'Farm suspended with ID'.concat(data_http.farm_id);
					eindex.wallData botname, message, actionmsg, statusmsg;
				else
					robot.messageRoom data_http.userid, coffee_error
		else
			robot.messageRoom data_http.userid,'Sorry, You are not authorized to do this';
					
	#terminate farm
	cmd_terminate_farm=new RegExp('@' + process.env.HUBOT_NAME + ' terminate farm (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_terminate_farm
		(msg) ->
			farm_id = msg.match[1]
			message = 'terminate farm '+farm_id;
			actionmsg = 'Farm terminated in Scalr';
			statusmsg = 'Success';
			
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.terminatecalrfarm.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,farm_id:farm_id,username:msg.message.user.name,userid:msg.message.room,approver:stdout.terminatecalrfarm.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'terminatecalrfarm',tckid:tckid};
						data = {"channel": stdout.terminatecalrfarm.admin,"text":"Request from"+payload.username+"Approve Request for terminate farm","message":"Approve Request for terminate farm",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'terminatecalrfarm',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.terminatecalrfarm.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				else
					farm_terminate.farm_terminate scalr_url, scalr_access_id, scalr_access_key, env_id, farm_id, (coffee_error, coffee_stdout, coffee_stderr) ->
						if coffee_error == null
							msg.send 'Farm terminated with ID'.concat(farm_id);
							eindex.wallData botname, message, actionmsg, statusmsg;
						else
							msg.reply coffee_error;
	)
				
	robot.router.post '/terminatecalrfarm', (request, response) ->
		data_http   = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			farm_terminate.farm_terminate scalr_url, scalr_access_id, scalr_access_key, env_id, data_http.farm_id, (coffee_error, coffee_stdout, coffee_stderr) ->
				if coffee_error == null
					robot.messageRoom data_http.userid, 'Farm terminated with ID'.concat(data_http.farm_id);
					eindex.wallData botname, message, actionmsg, statusmsg;
				else
					robot.messageRoom data_http.userid, coffee_error
		else
			robot.messageRoom data_http.userid,'Sorry, You are not authorized to do this';
					
	#clone farm 				
	cmd_clone_farm=new RegExp('@' + process.env.HUBOT_NAME + ' clone farm (.*) to (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_clone_farm
		(msg) ->
			farm_id = msg.match[1]
			new_farm_name = msg.match[2]
			message = 'clone farm '+farm_id+'to '+new_farm_name;
			actionmsg = 'Farm cloned in Scalr';
			statusmsg = 'Success';
			
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.clonescalrfarm.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,farm_id:farm_id,new_farm_name:new_farm_name,username:msg.message.user.name,userid:msg.message.room,approver:stdout.clonescalrfarm.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'clonescalrfarm',tckid:tckid};
						data = {"channel": stdout.clonescalrfarm.admin,"text":"Request from"+payload.username+"Approve Request for clone farm","message":"Approve Request for clone farm",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'clonescalrfarm',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.clonescalrfarm.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				else
					farm_clone.farm_clone scalr_url, scalr_access_id, scalr_access_key, env_id, farm_id, new_farm_name, (coffee_error, coffee_stdout, coffee_stderr) ->
						if coffee_error == null
							msg.send 'Farm cloned with ID : '.concat(coffee_stdout);
							eindex.wallData botname, message, actionmsg, statusmsg;
						else
							msg.reply coffee_error;
	)
				
	robot.router.post '/clonescalrfarm', (request, response) ->
		data_http   = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			farm_clone.farm_clone scalr_url, scalr_access_id, scalr_access_key, env_id, data_http.farm_id, data_http.new_farm_name, (coffee_error, coffee_stdout, coffee_stderr) ->
				if coffee_error == null
					robot.messageRoom data_http.userid, 'Farm cloned with ID : '.concat(coffee_stdout);
					eindex.wallData botname, message, actionmsg, statusmsg;
				else
					robot.messageRoom data_http.userid, coffee_error
		else
			robot.messageRoom data_http.userid,'Sorry, You are not authorized to do this';
