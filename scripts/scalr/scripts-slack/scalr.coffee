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
generate_id = require('./mongoConnt')
module.exports = (robot) ->
	robot.respond /help/i, (msg) ->
		msg.send 'print scalr farms\nprint scalr scripts\nprint scalr server <farm-id>\nprint scalr role <farm-id>\nprint scalr farm <farm-id>\ncreate farm <farm-name>\nexecute script <script-id> in server <server-id>\nlaunch farm <farm-id>\ndelete farm <farm-id>\nresume farm <farm-id>\nsuspend farm <farm-id>\nterminate farm <farm-id>\nclone farm <farm-id> to <new-farm-name>\ncreate role <role-name> in <farm-id> on <os-name( either windows or ubuntu )>\n**** NO SPECIAL CHARACTER IS ACCEPTED BY SCALR ****';
		
	#print scalr farms	
	robot.respond /print scalr farms/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.printscalrfarm.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.printscalrfarm.admin,podIp:pod_ip,callback_id='printscalrfarm',message:msg.message.text,tckid:tckid}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: print scalr farms \n approve or reject the request';
					robot.messageRoom(stdout.printscalrfarm.admin, data);
					msg.send 'Your request is waiting for approval by '+stdout.printscalrfarm.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				farm_list.farm_list scalr_url, scalr_access_id, scalr_access_key, env_id, (coffee_error, coffee_stdout, coffee_stderr) ->
					if coffee_error == null
						msg.send coffee_stdout
					else
						msg.reply coffee_error;
	
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
	robot.respond /print scalr scripts/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.printscalrscripts.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.printscalrscripts.admin,podIp:pod_ip,callback_id='printscalrscripts',smessage:msg.message.text,tckid:tckid}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: print scalr scripts \n approve or reject the request';
					robot.messageRoom(stdout.printscalrscripts.admin, data);
					msg.send 'Your request is waiting for approval by '+stdout.printscalrscripts.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				script_list.script_list scalr_url, scalr_access_id, scalr_access_key, env_id, (coffee_error, coffee_stdout, coffee_stderr) ->
					if coffee_error == null
						msg.send coffee_stdout
					else
						msg.reply coffee_error;
						
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
	robot.respond /print scalr server (.*)/i, (msg) ->
		farm_id = msg.match[1];
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.printscalrserver.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,farm_id:farm_id,username:msg.message.user.name,userid:msg.message.room,approver:stdout.printscalrserver.admin,podIp:pod_ip,callback_id='printscalrserver',message:msg.message.text,tckid:tckid}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: print scalr server \n approve or reject the request';
					robot.messageRoom(stdout.printscalrserver.admin, data);
					msg.send 'Your request is waiting for approval by '+stdout.printscalrserver.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				server_list.server_list scalr_url, scalr_access_id, scalr_access_key, env_id, farm_id, (coffee_error, coffee_stdout, coffee_stderr) ->
					if coffee_error == null
						msg.send coffee_stdout
					else
						msg.reply coffee_error;
				
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
	robot.respond /print scalr role (.*)/i, (msg) ->
		farm_id = msg.match[1];
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.printscalrroles.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,farm_id:farm_id,username:msg.message.user.name,userid:msg.message.room,approver:stdout.printscalrroles.admin,podIp:pod_ip,callback_id='printscalrroles',message:msg.message.text,tckid:tckid}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: print scalr role \n approve or reject the request';
					robot.messageRoom(stdout.printscalrroles.admin, data);
					msg.send 'Your request is waiting for approval by '+stdout.printscalrroles.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else 
				role_list.role_list scalr_url, scalr_access_id, scalr_access_key, env_id, farm_id, (coffee_error, coffee_stdout, coffee_stderr) ->
					if coffee_error == null
						msg.send coffee_stdout
					else
						msg.reply coffee_error;
				
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
	robot.respond /print scalr farm (.*)/i, (msg) ->
		farm_name = msg.match[1];
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.printscalrspecificfarm.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,farm_name:farm_name,username:msg.message.user.name,userid:msg.message.room,approver:stdout.printscalrspecificfarm.admin,podIp:pod_ip,callback_id='printscalrspecificfarm',message:msg.message.text,tckid:tckid}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: print scalr farm \n approve or reject the request';
					robot.messageRoom(stdout.printscalrspecificfarm.admin, data);
					msg.send 'Your request is waiting for approval by '+stdout.printscalrspecificfarm.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else 
				farm_search.farm_search scalr_url, scalr_access_id, scalr_access_key, env_id, farm_name, (coffee_error, coffee_stdout, coffee_stderr) ->
					if coffee_error == null
						msg.send coffee_stdout
					else
						msg.reply coffee_error;
				
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
	robot.respond /execute script (.*) in server (.*)/i, (msg) ->
		script_id = msg.match[1]
		server_id = msg.match[2];
		message = 'execute script '+script_id+'in server '+server_id;
		actionmsg = 'Script executed in Scalr Farm';
		statusmsg = 'Success';
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.executescriptinfarm.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,script_id:script_id,server_id:server_id,username:msg.message.user.name,userid:msg.message.room,approver:stdout.executescriptinfarm.admin,podIp:pod_ip,callback_id='executescriptinfarm',message:msg.message.text,tckid:tckid}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: execute script in server \n approve or reject the request';
					robot.messageRoom(stdout.executescriptinfarm.admin, data);
					msg.send 'Your request is waiting for approval by '+stdout.executescriptinfarm.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else 
				script_execute.script_execute scalr_url, scalr_access_id, scalr_access_key, env_id, script_id, server_id, (coffee_error, coffee_stdout, coffee_stderr) ->
					if coffee_error == null
						msg.send 'Script executed with ID : '.concat(coffee_stdout);
						eindex.wallData botname, message, actionmsg, statusmsg;
					else
						msg.reply coffee_error;
				
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
	robot.respond /create farm (.*)/i, (msg) ->
		farm_name = msg.match[1]
		message = 'create farm '+farm-name;
		actionmsg = 'Scalr farm created';
		statusmsg = 'Success';
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.createscalrfarm.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,farm_name:farm_name,username:msg.message.user.name,userid:msg.message.room,approver:stdout.createscalrfarm.admin,podIp:pod_ip,callback_id='createscalrfarm',message:msg.message.text,tckid:tckid}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: create farm \n approve or reject the request';
					robot.messageRoom(stdout.createscalrfarm.admin, data);
					msg.send 'Your request is waiting for approval by '+stdout.createscalrfarm.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else	
				farm_create.farm_create scalr_url, scalr_access_id, scalr_access_key, env_id, farm_name, (coffee_error, coffee_stdout, coffee_stderr) ->
					if coffee_error == null
						msg.send 'Farm created with ID : '.concat(coffee_stdout);
						eindex.wallData botname, message, actionmsg, statusmsg;
					else
						msg.reply coffee_error;
					
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
	robot.respond /create role (.*) in (.*) on (.*)/i, (msg) ->
		farm_name = msg.match[2]
		role_name = msg.match[1]
		os_name = msg.match[3]
		message = 'create role '+role_name+'in '+farm-name+'on '+os_name;
		actionmsg = 'Role created in scalr farm';
		statusmsg = 'Success';
		os_name = os_name.toLowerCase();
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.createscalrroleinfarm.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,farm_name:farm_name,role_name:role_name,os_name:os_name,username:msg.message.user.name,userid:msg.message.room,approver:stdout.createscalrroleinfarm.admin,podIp:pod_ip,callback_id='createscalrroleinfarm',message:msg.message.text,tckid:tckid}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: create role \n approve or reject the request';
					robot.messageRoom(stdout.createscalrroleinfarm.admin, data);
					msg.send 'Your request is waiting for approval by '+stdout.createscalrroleinfarm.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else	
				role_create.role_create scalr_url, scalr_access_id, scalr_access_key, env_id, farm_name, role_name, os_name, (coffee_error, coffee_stdout, coffee_stderr) ->
					if coffee_error == null
						msg.send 'Role created with ID : '.concat(coffee_stdout);
						eindex.wallData botname, message, actionmsg, statusmsg;
					else
						msg.reply coffee_error;
				
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
	robot.respond /delete farm (.*)/i, (msg) ->
		farm_name = msg.match[1]
		message= 'delete farm '+farm_name;
		actionmsg = 'Farm deleted in Scalr';
		statusmsg = 'Success';
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.deletescalrfarm.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,farm_name:farm_name,username:msg.message.user.name,userid:msg.message.room,approver:stdout.deletescalrfarm.admin,podIp:pod_ip,callback_id='deletescalrfarm',message:msg.message.text,tckid:tckid}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: delete farm \n approve or reject the request';
					robot.messageRoom(stdout.deletescalrfarm.admin, data);
					msg.send 'Your request is waiting for approval by '+stdout.deletescalrfarm.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else	
				farm_delete.farm_delete scalr_url, scalr_access_id, scalr_access_key, env_id, farm_name, (coffee_error, coffee_stdout, coffee_stderr) ->
					if coffee_error == null
						msg.send 'Farm deleted : '.concat(farm_name);
						eindex.wallData botname, message, actionmsg, statusmsg;
					else
						msg.reply coffee_error;
				
	robot.router.post '/deletescalrfarm', (request, response) ->
		data_http   = if request.body.payload? then JSON.parse request.body.payload else request.body
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
	robot.respond /launch farm (.*)/i, (msg) ->
		farm_id = msg.match[1]
		message = 'launch farm '+farm_id;
		actionmsg = 'Farm launched in Scalr';
		statusmsg = 'Success';
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.launchscalrfarm.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,farm_id:farm_id,username:msg.message.user.name,userid:msg.message.room,approver:stdout.launchscalrfarm.admin,podIp:pod_ip,callback_id='launchscalrfarm',message:msg.message.text,tckid:tckid}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: launch farm \n approve or reject the request';
					robot.messageRoom(stdout.launchscalrfarm.admin, data);
					msg.send 'Your request is waiting for approval by '+stdout.launchscalrfarm.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else	
				farm_launch.farm_launch scalr_url, scalr_access_id, scalr_access_key, env_id, farm_id, (coffee_error, coffee_stdout, coffee_stderr) ->
					if coffee_error == null
						msg.send 'Farm launched with ID'.concat(farm_id);
						eindex.wallData botname, message, actionmsg, statusmsg;
					else
						msg.reply coffee_error;
	
	
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
	robot.respond /resume farm (.*)/i, (msg) ->
		farm_id = msg.match[1]
		message = 'resume farm '+farm_id;
		actionmsg = 'Farm resumed in Scalr';
		statusmsg = 'Success';
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.resumescalrfarm.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,farm_id:farm_id,username:msg.message.user.name,userid:msg.message.room,approver:stdout.resumescalrfarm.admin,podIp:pod_ip,callback_id='resumescalrfarm',message:msg.message.text,tckid:tckid}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: resume farm \n approve or reject the request';
					robot.messageRoom(stdout.resumescalrfarm.admin, data);
					msg.send 'Your request is waiting for approval by '+stdout.resumescalrfarm.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else 
				farm_resume.farm_resume scalr_url, scalr_access_id, scalr_access_key, env_id, farm_id, (coffee_error, coffee_stdout, coffee_stderr) ->
					if coffee_error == null
						msg.send 'Farm resumed with ID'.concat(farm_id);
						eindex.wallData botname, message, actionmsg, statusmsg;
					else
						msg.reply coffee_error;
				
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
	robot.respond /suspend farm (.*)/i, (msg) ->
		farm_id = msg.match[1]
		message = 'suspend farm '+farm_id;
		actionmsg = 'Farm suspended in Scalr';
		statusmsg = 'Success';
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.suspendscalrfarm.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,farm_id:farm_id,username:msg.message.user.name,userid:msg.message.room,approver:stdout.suspendscalrfarm.admin,podIp:pod_ip,callback_id='suspendscalrfarm',message:msg.message.text,tckid:tckid}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: suspend farm \n approve or reject the request';
					robot.messageRoom(stdout.suspendscalrfarm.admin, data);
					msg.send 'Your request is waiting for approval by '+stdout.suspendscalrfarm.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				farm_suspend.farm_suspend scalr_url, scalr_access_id, scalr_access_key, env_id, farm_id, (coffee_error, coffee_stdout, coffee_stderr) ->
					if coffee_error == null
						msg.send 'Farm suspended with ID'.concat(farm_id);
						eindex.wallData botname, message, actionmsg, statusmsg;
					else
						msg.reply coffee_error;
				
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
	robot.respond /terminate farm (.*)/i, (msg) ->
		farm_id = msg.match[1]
		message = 'terminate farm '+farm_id;
		actionmsg = 'Farm terminated in Scalr';
		statusmsg = 'Success';
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.terminatecalrfarm.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,farm_id:farm_id,username:msg.message.user.name,userid:msg.message.room,approver:stdout.terminatecalrfarm.admin,podIp:pod_ip,callback_id='terminatecalrfarm',message:msg.message.text,tckid:tckid}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: terminate farm \n approve or reject the request';
					robot.messageRoom(stdout.terminatecalrfarm.admin, data);
					msg.send 'Your request is waiting for approval by '+stdout.terminatecalrfarm.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				farm_terminate.farm_terminate scalr_url, scalr_access_id, scalr_access_key, env_id, farm_id, (coffee_error, coffee_stdout, coffee_stderr) ->
					if coffee_error == null
						msg.send 'Farm terminated with ID'.concat(farm_id);
						eindex.wallData botname, message, actionmsg, statusmsg;
					else
						msg.reply coffee_error;
				
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
	robot.respond /clone farm (.*) to (.*)/i, (msg) ->
		farm_id = msg.match[1]
		new_farm_name = msg.match[2]
		message = 'clone farm '+farm_id+'to '+new_farm_name;
		actionmsg = 'Farm cloned in Scalr';
		statusmsg = 'Success';
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.clonescalrfarm.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,farm_id:farm_id,username:msg.message.user.name,userid:msg.message.room,approver:stdout.clonescalrfarm.admin,podIp:pod_ip,callback_id='clonescalrfarm',message:msg.message.text,tckid:tckid}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: clone farm \n approve or reject the request';
					robot.messageRoom(stdout.clonescalrfarm.admin, data);
					msg.send 'Your request is waiting for approval by '+stdout.clonescalrfarm.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				farm_clone.farm_clone scalr_url, scalr_access_id, scalr_access_key, env_id, farm_id, new_farm_name, (coffee_error, coffee_stdout, coffee_stderr) ->
					if coffee_error == null
						msg.send 'Farm cloned with ID : '.concat(coffee_stdout);
						eindex.wallData botname, message, actionmsg, statusmsg;
					else
						msg.reply coffee_error;
				
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
