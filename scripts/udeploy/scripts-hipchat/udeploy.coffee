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

###
Coffee script used for:
Creating user,components,resourses,applications.
Viewing user,components,resourses,applications.

Set of bot commands:
1. create security token
2. view user <user-name>
3. delete user <user-name>
4. create user <user-name>
5. create component <component-name>
6. delete resource <resource-name>
7. create resource <resource-name>
8. view environment of application <application-name>
9. view components of application <application-name>
10. view application <application-name>
11. view component <component-name>
12. list applications
13. list resources
14. list components

Env to set:
1. UDEPLOY_URL
2. UDEPLOY_USER_ID
3. UDEPLOY_PASSWORD
4. AUTHREALM

Dependencies:
1. request
###

udeploy_url = process.env.UDEPLOY_URL
udeploy_user_id = process.env.UDEPLOY_USER_ID
udeploy_password =  process.env.UDEPLOY_PASSWORD
botname = process.env.HUBOT_NAME || ''
pod_ip = process.env.MY_POD_IP || ''

get_all_component = require('./get_all_component.js');
get_all_resources = require('./get_all_resources.js');
get_all_application = require('./get_all_application.js');

get_specific_component = require('./get_specific_component.js');
get_specific_application = require('./get_specific_application.js');

get_component_specific_application = require('./get_component_specific_application.js');
get_environment_specific_application = require('./get_environment_specific_application.js');

create_resource = require('./create_resource.js');
delete_resource = require('./delete_resource.js');
create_component = require('./create_component.js');

create_user = require('./create_user.js');
delete_user = require('./delete_user.js');
info_user = require('./info_user.js');

create_token = require('./create_token.js');
app_deploy = require('./app_deploy.js');
request=require('request')
readjson = require './readjson.js'

index = require('./index')

uniqueId = (length=8) ->
  id = ""
  id += Math.random().toString(36).substr(2) while id.length < length
  id.substr 0, length

  
generate_id = require('./mongoConnt')

module.exports = (robot) ->
	robot.respond /help/i, (msg) ->
		dt = 'create security token\nview user <user-name>\ndelete user <user-name>\ncreate user <user-name>\ncreate component <component-name>\ndelete resource <resource-name>\ncreate resource <resource-name>\nview environment of application <application-name>\nview components of application <application-name>\nview application <application-name>\nview component <component-name>\nlist applications\nlist resources\nlist components'
		msg.send dt
		msg.send 'deploy <app_name> process <process_name> env <environment_name> version <version_number> component <component_name>\n *deploy HelloWorldAppln process HelloWorldApplnProcess env Dev version 3.0 component HelloWorld*\nstart watching *It\'ll notify you if any application/component/resource is created by anybody* ';
		setTimeout (->index.passData dt),1000
	

	#list components	
	robot.respond /list components/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.udeploycomponentslist.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,approver:stdout.udeploycomponentslist.admin,podIp:process.env.MY_POD_IP,callback_id: 'udeploycomponentslist',message:msg.message.text}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: '+msg.match[0];
					robot.messageRoom(stdout.udeploycomponentslist.admin, data);
					msg.send 'Your request is waiting for approval from '+stdout.udeploycomponentslist.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				get_all_component.get_all_component udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
						
	robot.router.post '/udeploycomponentslist', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approved'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			get_all_component.get_all_component udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
					setTimeout (->index.passData stdout),1000
				else
					robot.messageRoom data_http.userid, error
					setTimeout (->index.passData error),1000
		else
			robot.messageRoom data_http.userid, 'Your request for list components was rejected';
	
	#list resources
	robot.respond /list resources/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.udeployresourceslist.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,approver:stdout.udeployresourceslist.admin,podIp:process.env.MY_POD_IP,callback_id: 'udeployresourceslist',message:msg.message.text}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: '+msg.match[0];
					robot.messageRoom(stdout.udeployresourceslist.admin, data);
					msg.send 'Your request is waiting for approval by '+stdout.udeployresourceslist.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				get_all_resources.get_all_resources udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
						
	robot.router.post '/udeployresourceslist', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			get_all_resources.get_all_resources udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
					setTimeout (->index.passData stdout),1000
				else
					robot.messageRoom data_http.userid, error
					setTimeout (->index.passData error),1000
		else
			robot.messageRoom data_http.userid, 'Your request for list resources was rejected';
	
	#list applications
	robot.respond /list applications/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.udeployapllicationslist.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,approver:stdout.udeployapllicationslist.admin,podIp:process.env.MY_POD_IP,callback_id: 'udeployapllicationslist',message:msg.message.text}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: '+msg.match[0];
					robot.messageRoom(stdout.udeployapllicationslist.admin, data);
					msg.send 'Your request is waiting for approval from '+stdout.udeployapllicationslist.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				get_all_application.get_all_application udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
						
	robot.router.post '/udeployapllicationslist', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approved'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			get_all_application.get_all_application udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
					setTimeout (->index.passData stdout),1000
				else
					robot.messageRoom data_http.userid, error
					setTimeout (->index.passData error),1000
		else
			robot.messageRoom data_http.userid, 'Your request for list applications was rejected';
	
	#view component
	robot.respond /view component (.*)/i, (msg) ->
		component_name = msg.match[1];
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.udeploycomponent.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,approver:stdout.udeploycomponent.admin,podIp:process.env.MY_POD_IP,callback_id: 'udeploycomponent',component_name:component_name,message:msg.message.text}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: '+msg.match[0];
					robot.messageRoom(stdout.udeploycomponent.admin, data);
					msg.send 'Your request is waiting for approval from '+stdout.udeploycomponent.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				get_specific_component.get_specific_component component_name, udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
						
	robot.router.post '/udeploycomponent', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approved'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			get_specific_component.get_specific_component data_http.component_name, udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
					setTimeout (->index.passData stdout),1000
				else
					robot.messageRoom data_http.userid, error
					setTimeout (->index.passData error),1000
		else
			robot.messageRoom data_http.userid, 'Your request for view component was rejected';
	
	#view application
	robot.respond /view application (.*)/i, (msg) ->
		application_name = msg.match[1];
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.udeployapplication.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,approver:stdout.udeployapplication.admin,podIp:process.env.MY_POD_IP,callback_id: 'udeployapplication',application_name:application_name,message:msg.message.text}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: '+msg.match[0];
					robot.messageRoom(stdout.udeployapplication.admin, data);
					msg.send 'Your request is waiting for approval from '+stdout.udeployapplication.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
					
			else
				get_specific_application.get_specific_application application_name, udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
						
	robot.router.post '/udeployapplication', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approved'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			get_specific_application.get_specific_application data_http.application_name, udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
					setTimeout (->index.passData stdout),1000
				else
					robot.messageRoom data_http.userid, error
					setTimeout (->index.passData error),1000
		else
			robot.messageRoom data_http.userid, 'Your request for view application was rejected';
	
	#view components of application
	robot.respond /view components of application (.*)/i, (msg) ->
		componentapplication = msg.match[1];
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.udeploycomponentapplication.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,approver:stdout.udeploycomponentapplication.admin,podIp:process.env.MY_POD_IP,componentapplication:componentapplication,callback_id: 'udeploycomponentapplication',message:msg.message.text}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: '+msg.match[0];
					robot.messageRoom(stdout.udeploycomponentapplication.admin, data);
					msg.send 'Your request is waiting for approval from '+stdout.udeploycomponentapplication.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				get_component_specific_application.get_component_specific_application componentapplication, udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
						
	robot.router.post '/udeploycomponentapplication', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approved'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			get_component_specific_application.get_component_specific_application data_http.componentapplication, udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
					setTimeout (->index.passData stdout),1000
				else
					robot.messageRoom data_http.userid, error
					setTimeout (->index.passData error),1000
		else
			robot.messageRoom data_http.userid, 'Your request for view components of application was rejected';
	
	#view environment of application
	robot.respond /view environment of application (.*)/i, (msg) ->
		environmentapplication = msg.match[1];
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.udeployenvironmentapplication.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					
						
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,approver:stdout.udeployenvironmentapplication.admin,podIp:process.env.MY_POD_IP,environmentapplication:environmentapplication,callback_id: 'udeployenvironmentapplication',message:msg.message.text}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: '+msg.match[0];
					robot.messageRoom(stdout.udeployenvironmentapplication.admin, data);
					msg.send 'Your request is waiting for approval from '+stdout.udeployenvironmentapplication.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				get_environment_specific_application.get_environment_specific_application environmentapplication, udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
						
	robot.router.post '/udeployenvironmentapplication', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approved'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			get_environment_specific_application.get_environment_specific_application data_http.environmentapplication, udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
					setTimeout (->index.passData stdout),1000
				else
					robot.messageRoom data_http.userid, error
					setTimeout (->index.passData error),1000
		else
			robot.messageRoom data_http.userid, 'Your request for view environment of application was rejected';
	
	#create resource
	robot.respond /create resource (.*)/i, (msg) ->
		resource = msg.match[1];
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.udeploycreateresource.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,approver:stdout.udeploycreateresource.admin,podIp:process.env.MY_POD_IP,callback_id: 'udeploycreateresource',message:msg.message.text,resource:resource}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: '+msg.match[0];
					robot.messageRoom(stdout.udeploycreateresource.admin, data);
					msg.send 'Your request is waiting for approval from '+stdout.udeploycreateresource.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				create_resource.create_resource resource, udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
						message = msg.match[0];
						actionmsg = 'u-Deploy resource created'
						statusmsg = 'Success';
						index.wallData botname, message, actionmsg, statusmsg;
					else
						msg.send error;
						setTimeout (->index.passData error),1000
	
	
	robot.router.post '/udeploycreateresource', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approved'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			create_resource.create_resource data_http.resource, udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
					setTimeout (->index.passData stdout),1000
					message = 'create resource '+data_http.resource;
					actionmsg = 'u-Deploy resource created'
					statusmsg = 'Success';
					index.wallData botname, message, actionmsg, statusmsg;
				else
					robot.messageRoom data_http.userid, error;
					setTimeout (->index.passData error),1000
		else
			robot.messageRoom data_http.userid, 'Your request to create u-Deploy resource was rejected';

	
	#delete resource
	robot.respond /delete resource (.*)/i, (msg) ->
		resource = msg.match[1];
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.udeploydeleteresource.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,approver:stdout.udeploydeleteresource.admin,podIp:process.env.MY_POD_IP,callback_id: 'udeploydeleteresource',message:msg.message.text,resource:resource,tckid:tckid}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: '+msg.match[0];
					robot.messageRoom(stdout.udeploydeleteresource.admin, data);
					msg.send 'Your request is waiting for approval from '+stdout.udeploydeleteresource.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				delete_resource.delete_resource resource, udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
						message = msg.match[0] 
						actionmsg = 'u-Deploy resource deleted'
						statusmsg = 'Success';
						index.wallData botname, message, actionmsg, statusmsg;
					else
						msg.send error;
						setTimeout (->index.passData error),1000
	
	
	robot.router.post '/udeploydeleteresource', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approved'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			delete_resource.delete_resource data_http.resource, udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
					setTimeout (->index.passData stdout),1000
					message = 'delete resource '+data_http.resource;
					actionmsg = 'u-Deploy resource deleted'
					statusmsg = 'Success';
					index.wallData botname, message, actionmsg, statusmsg;
				else			
					robot.messageRoom data_http.userid, error;
					setTimeout (->index.passData error),1000
		else
			robot.messageRoom data_http.userid, 'Your request for deleting u-Deploy resource was rejected';
	
	#create component
	robot.respond /create component (.*)/i, (msg) ->
		component = msg.match[1];
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.udeploycreaterecomponent.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,approver:stdout.udeploycreaterecomponent.admin,podIp:process.env.MY_POD_IP,callback_id: 'udeploycreaterecomponent',message:msg.message.text,component:component,tckid:tckid}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: '+msg.match[0];
					robot.messageRoom(stdout.udeploycreaterecomponent.admin, data);
					msg.send 'Your request is waiting for approval from '+stdout.udeploycreaterecomponent.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				create_component.create_component component, udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
						message = msg.match[0];
						actionmsg = 'u-Deploy component(s) created'
						statusmsg = 'Success';
						index.wallData botname, message, actionmsg, statusmsg;
					else
						msg.send error;
						setTimeout (->index.passData error),1000
	
	robot.router.post '/udeploycreaterecomponent', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approved'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			create_component.create_component data_http.component, udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
					setTimeout (->index.passData stdout),1000
					message = 'create component '+data_http.component;
					actionmsg = 'u-Deploy component(s) created'
					statusmsg = 'Success';
					index.wallData botname, message, actionmsg, statusmsg;
				else
					robot.messageRoom data_http.userid, error;
					setTimeout (->index.passData error),1000
		else
			robot.messageRoom data_http.userid, 'Your request for creating u-Deploy component was rejected';
	
	#create user
	robot.respond /create user (.*)/i, (msg) ->
		user_name = msg.match[1];
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			unique_password = uniqueId(5);
			if stdout.udeploycreatereuser.workflowflag == true
				generate_id.getNextSequence (err,id) ->	
					tckid=id
					
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,approver:stdout.udeploycreatereuser.admin,podIp:process.env.MY_POD_IP,callback_id: 'udeploycreatereuser',message:msg.message.text,user_name:user_name,tckid:tckid,unique_password:unique_password}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: '+msg.match[0];
					robot.messageRoom(stdout.udeploycreatereuser.admin, data);
					msg.send 'Your request is waiting for approval from '+stdout.udeploycreatereuser.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				create_user.create_user user_name, unique_password, udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
						actionmsg = 'u-Deploy user(s) created'
						statusmsg = 'Success';
						index.wallData botname, message, actionmsg, statusmsg;
					else
						msg.send error;
						setTimeout (->index.passData error),1000
	
	robot.router.post '/udeploycreatereuser', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approved'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			create_user.create_user data_http.user_name, data_http.unique_password, udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
					setTimeout (->index.passData stdout),1000
					message = 'create user '+data_http.user_name
					actionmsg = 'u-Deploy user(s) created'
					statusmsg = 'Success';
					index.wallData botname, message, actionmsg, statusmsg;
				else
					robot.messageRoom data_http.userid, error;
					setTimeout (->index.passData error),1000
		else
			robot.messageRoom data_http.userid, 'Your request to create u-Deploy user was rejected';
	
	#delete user
	robot.respond /delete user (.*)/i, (msg) ->
		user_name = msg.match[1];
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.udeploydeletereuser.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,approver:stdout.udeploydeletereuser.admin,podIp:process.env.MY_POD_IP,callback_id: 'udeploydeletereuser',message:msg.message.text,user_name:user_name,tckid:tckid}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: '+msg.match[0];
					robot.messageRoom(stdout.udeploydeletereuser.admin, data);
					msg.send 'Your request is waiting for approval from '+stdout.udeploydeletereuser.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				delete_user.delete_user user_name, udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
						message = msg.match[0]
						actionmsg = 'u-Deploy user(s) deleted'
						statusmsg = 'Success';
						index.wallData botname, message, actionmsg, statusmsg;
					else
						msg.send error;
						setTimeout (->index.passData error),1000
	
	robot.router.post '/udeploydeletereuser', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approved'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			delete_user.delete_user data_http.user_name, udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
					setTimeout (->index.passData stdout),1000
					message = 'delete user '+data_http.user_name;
					actionmsg = 'u-Deploy user(s) deleted'
					statusmsg = 'Success';
					index.wallData botname, message, actionmsg, statusmsg;
				else
					robot.messageRoom data_http.userid, error;
					setTimeout (->index.passData error),1000
		else
			robot.messageRoom data_http.userid, 'Your request for deleting u-Deploy user was rejected';
	
	#view user
	robot.respond /view user (.*)/i, (msg) ->
		user_name = msg.match[1];
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.udeployshowreuser.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,approver:stdout.udeployshowreuser.admin,podIp:process.env.MY_POD_IP,callback_id: 'udeployshowreuser',message:msg.message.text,user_name:user_name}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: '+msg.match[0];
					robot.messageRoom(stdout.udeployshowreuser.admin, data);
					msg.send 'Your request is waiting for approval from '+stdout.udeployshowreuser.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				info_user.info_user user_name, udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
						
	robot.router.post '/udeployshowreuser', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approved'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			info_user.info_user data_http.user_name, udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
					setTimeout (->index.passData stdout),1000
				else
					robot.messageRoom data_http.userid, error
					setTimeout (->index.passData error),1000
		else
			robot.messageRoom data_http.userid, 'Your request for view user was rejected';
	
	#create security token
	robot.respond /create security token/i, (msg) ->
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.udeploycreatetoken.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,approver:stdout.udeploycreatetoken.admin,podIp:process.env.MY_POD_IP,callback_id: 'udeploycreatetoken',message:msg.message.text,tckid:tckid}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: '+msg.match[0];
					robot.messageRoom(stdout.udeploycreatetoken.admin, data);
					msg.send 'Your request is waiting for approval from '+stdout.udeploycreatetoken.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				unique_password = uniqueId(5);
				create_token.create_token udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
					if error == "null"
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
						message = msg.match[0];
						actionmsg = 'u-Deploy token(s) created'
						statusmsg = 'Success';
						index.wallData botname, message, actionmsg, statusmsg;
					else
						msg.send error;
						setTimeout (->index.passData error),1000
	
	robot.router.post '/udeploycreatetoken', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approved'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			create_token.create_token udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
				if error == "null"
					robot.messageRoom data_http.userid, stdout;
					setTimeout (->index.passData stdout),1000
					message = 'create security token';
					actionmsg = 'u-Deploy token(s) created'
					statusmsg = 'Success';
					index.wallData botname, message, actionmsg, statusmsg;
				else
					robot.messageRoom data_http.userid, error;
					setTimeout (->index.passData error),1000
		else
			robot.messageRoom data_http.userid, 'Your request for creating u-Deploy security token was rejected';
	
	#deploy 
	robot.respond /deploy (.*) process (.*) env (.*) version (.*) component (.*)/i, (msg) ->
		#deploy HelloWorldAppln process HelloWorldApplnProcess env Dev version 3.0 component HelloWorld
		#deploy <app_name> process <process_name> env <environment_name> version <version_number> component <component_name>
		app_name = msg.match[1];
		app_process = msg.match[2];
		env = msg.match[3];
		version = msg.match[4];
		component = msg.match[5];
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.udeployappdeploy.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
										
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,approver:stdout.udeployappdeploy.admin,podIp:pod_ip,callback_id: 'udeployappdeploy',message:msg.message.text,tckid:tckid,app_name:app_name,app_process:app_process,env:env,version:version,component:component}
					data='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: '+msg.match[0];
					robot.messageRoom(stdout.udeployappdeploy.admin, data);
					msg.send 'Your request is waiting for approval by '+stdout.udeployappdeploy.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				msg.reply 'Your process is in progress. Once it\'s done you\'ll be notified.';
				app_deploy.app_deploy udeploy_url, udeploy_user_id, udeploy_password, app_name, app_process, env, version, component, (error, stdout, stderr) ->
					if error == "null"
						msg.reply stdout;
					else
						msg.reply error;
	
	robot.router.post '/udeployappdeploy', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approved'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			app_deploy.app_deploy udeploy_url, udeploy_user_id, udeploy_password, data_http.app_name, data_http.app_process, data_http.env, data_http.version, data_http.component, (error, stdout, stderr) ->
				if error == "null"
					setTimeout (->index.passData stdout),1000
					message = 'deploy '+data_http.app_name+'process '+data_http.app_process+'env '+data_http.env+'version '+data_http.version+'component '+data_http.component;
					actionmsg = 'u-Deploy application deployed';
					statusmsg = 'Success';
					index.wallData botname, message, actionmsg, statusmsg;
					robot.messageRoom data_http.userid, stdout;
				else
					setTimeout (->index.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			robot.messageRoom data_http.userid, 'You are not authorized.';
