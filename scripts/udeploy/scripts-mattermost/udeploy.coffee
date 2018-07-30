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

readjson = require './readjson.js'
request=require('request')
index = require('./index')

uniqueId = (length=8) ->
  id = ""
  id += Math.random().toString(36).substr(2) while id.length < length
  id.substr 0, length

generate_id = require('./mongoConnt')

module.exports = (robot) ->
	cmd=new RegExp('@' + process.env.HUBOT_NAME + ' help')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd
		(msg) ->
			dt = 'create security token\nview user <user-name>\ndelete user <user-name>\ncreate user <user-name>\ncreate component <component-name>\ndelete resource <resource-name>\ncreate resource <resource-name>\nview environment of application <application-name>\nview components of application <application-name>\nview application <application-name>\nview component <component-name>\nlist applications\nlist resources\nlist components'
			msg.send dt
			msg.send 'deploy <app_name> process <process_name> env <environment_name> version <version_number> component <component_name>\n *deploy HelloWorldAppln process HelloWorldApplnProcess env Dev version 3.0 component HelloWorld*\nstart watching *It\'ll notify you if any application/component/resource is created by anybody* ';
			setTimeout (->index.passData dt),1000
	)
	#list components
	cmd_components=new RegExp('@' + process.env.HUBOT_NAME + ' list components')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_components
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.udeploycomponentslist.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Set APPROVAL_APP_URL
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.udeploycomponentslist.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'udeploycomponentslist',tckid:tckid};
						data = {"channel": stdout.udeploycomponentslist.admin,"text":"Request from"+payload.username+"Approve Request for listing components","message":"Approve Request for listing components",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'udeploycomponentslist',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							
						msg.send 'Your request is waiting for approval from '.concat(stdout.udeploycomponentslist.admin);
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
	)
	robot.router.post '/udeploycomponentslist', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
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
	cmd_resources=new RegExp('@' + process.env.HUBOT_NAME + ' list resources')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_resources
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.udeployresourceslist.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Set APPROVAL_APP_URL
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.udeployresourceslist.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'udeployresourceslist',tckid:tckid};
						data = {"channel": stdout.udeployresourceslist.admin,"text":"Request from"+payload.username+"Approve Request for listing resources","message":"Approve Request for listing resources",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'udeployresourceslist',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						
						msg.send 'Your request is waiting for approval from '.concat(stdout.udeployresourceslist.admin);
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
	)
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
	cmd_applications=new RegExp('@' + process.env.HUBOT_NAME + ' list applications')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_applications
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.udeployapllicationslist.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Set APPROVAL_APP_URL
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.udeployapllicationslist.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'udeployapllicationslist',tckid:tckid};
						data = {"channel": stdout.udeployapllicationslist.admin,"text":"Request from"+payload.username+"Approve Request for listing applications","message":"Approve Request for listing applications",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'udeployapllicationslist',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						
						msg.send 'Your request is waiting for approval from '.concat(stdout.udeployapllicationslist.admin);
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
	)
	
	robot.router.post '/udeployapllicationslist', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
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
	cmd_component=new RegExp('@' + process.env.HUBOT_NAME + ' view component (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_component
		(msg) ->
			component_name = msg.match[1];
			
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.udeploycomponent.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Set APPROVAL_APP_URL
						payload={botname:process.env.HUBOT_NAME,component_name:component_name,username:msg.message.user.name,userid:msg.message.room,approver:stdout.udeploycomponent.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'udeploycomponent',tckid:tckid};
						data = {"channel": stdout.udeploycomponent.admin,"text":"Request from"+payload.username+"Approve Request for view component","message":"Approve Request for view component",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'udeploycomponent',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						
						msg.send 'Your request is waiting for approval from '.concat(stdout.udeploycomponent.admin);
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
	)
	
	robot.router.post '/udeploycomponent', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
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
	cmd_application=new RegExp('@' + process.env.HUBOT_NAME + ' view application (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_application
		(msg) ->
			application_name = msg.match[1];
			
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.udeployapplication.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Set APPROVAL_APP_URL
						payload={botname:process.env.HUBOT_NAME,application_name:application_name,username:msg.message.user.name,userid:msg.message.room,approver:stdout.udeployapplication.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'udeployapplication',tckid:tckid};
						data = {"channel": stdout.udeployapplication.admin,"text":"Request from"+payload.username+"Approve Request for view application","message":"Approve Request for view application",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'udeployapplication',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							
						msg.send 'Your request is waiting for approval from '.concat(stdout.udeployapplication.admin);
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
	)
	
	robot.router.post '/udeployapplication', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
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
	cmd_component_of_application=new RegExp('@' + process.env.HUBOT_NAME + ' view components of application (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_component_of_application
		(msg) ->
			componentapplication = msg.match[1];
			
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.udeploycomponentapplication.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Set APPROVAL_APP_URL
						payload={botname:process.env.HUBOT_NAME,componentapplication:componentapplication,username:msg.message.user.name,userid:msg.message.room,approver:stdout.udeploycomponentapplication.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'udeploycomponentapplication',tckid:tckid};
						data = {"channel": stdout.udeploycomponentapplication.admin,"text":"Request from"+payload.username+"Approve Request for view components of application","message":"Approve Request for view components of application",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'udeploycomponentapplication',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						
						msg.send 'Your request is waiting for approval from '.concat(stdout.udeploycomponentapplication.admin);
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
	)
	
	robot.router.post '/udeploycomponentapplication', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
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
	cmd_environment_of_application=new RegExp('@' + process.env.HUBOT_NAME + ' view environment of application (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_environment_of_application
		(msg) ->
			environmentapplication = msg.match[1];
			
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.udeployenvironmentapplication.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Set APPROVAL_APP_URL
						payload={botname:process.env.HUBOT_NAME,environmentapplication:environmentapplication,username:msg.message.user.name,userid:msg.message.room,approver:stdout.udeployenvironmentapplication.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'udeployenvironmentapplication',tckid:tckid};
						data = {"channel": stdout.udeployenvironmentapplication.admin,"text":"Request from"+payload.username+"Approve Request for view environment of application","message":"Approve Request for view environment of application",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'udeployenvironmentapplication',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						
						msg.send 'Your request is waiting for approval from '.concat(stdout.udeployenvironmentapplication.admin);
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
	)
	
	robot.router.post '/udeployenvironmentapplication', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
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
	cmd_create_resource=new RegExp('@' + process.env.HUBOT_NAME + ' create resource (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_create_resource
		(msg) ->
			resource = msg.match[1];
			
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.udeploycreateresource.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Set APPROVAL_APP_URL
						payload={botname:process.env.HUBOT_NAME,resource:resource,username:msg.message.user.name,userid:msg.message.room,approver:stdout.udeploycreateresource.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'udeploycreateresource',tckid:tckid};
						data = {"channel": stdout.udeploycreateresource.admin,"text":"Request from"+payload.username+"Approve Request for create resource","message":"Approve Request for create resource",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'udeploycreateresource',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						
						msg.send 'Your request is waiting for approval from '.concat(stdout.udeploycreateresource.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				else
					create_resource.create_resource resource, udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
						if error == "null"
							msg.send stdout;
							setTimeout (->index.passData stdout),1000
							message=msg.match[0];
							actionmsg = 'u-Deploy resource created'
							statusmsg = 'Success';
							index.wallData botname, message, actionmsg, statusmsg;
						else
							msg.send error;
							setTimeout (->index.passData error),1000
	)
	robot.router.post '/udeploycreateresource', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
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
			robot.messageRoom data_http.userid, 'Your request to create resource was rejected';

	#delete resource 
	cmd_delete_resource=new RegExp('@' + process.env.HUBOT_NAME + ' delete resource (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_delete_resource
		(msg) ->
			resource = msg.match[1];
			
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.udeploydeleteresource.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Set APPROVAL_APP_URL
						payload={botname:process.env.HUBOT_NAME,resource:resource,username:msg.message.user.name,userid:msg.message.room,approver:stdout.udeploydeleteresource.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'udeploydeleteresource',tckid:tckid};
						data = {"channel": stdout.udeploydeleteresource.admin,"text":"Request from"+payload.username+"Approve Request for delete resource","message":"Approve Request for delete resource",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'udeploydeleteresource',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						
						msg.send 'Your request is waiting for approval from '.concat(stdout.udeploydeleteresource.admin);
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
	)
	robot.router.post '/udeploydeleteresource', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
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
	cmd_create_component=new RegExp('@' + process.env.HUBOT_NAME + ' create component (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_create_component
		(msg) ->
			component = msg.match[1];
			
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.udeploycreaterecomponent.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Set APPROVAL_APP_URL
						payload={botname:process.env.HUBOT_NAME,component:component,username:msg.message.user.name,userid:msg.message.room,approver:stdout.udeploycreaterecomponent.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'udeploycreaterecomponent',tckid:tckid};
						data = {"channel": stdout.udeploycreaterecomponent.admin,"text":"Request from"+payload.username+"Approve Request for create component","message":"Approve Request for create component",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'udeploycreaterecomponent',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						
						msg.send 'Your request is waiting for approval from '.concat(stdout.udeploycreaterecomponent.admin);
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
	)
	robot.router.post '/udeploycreaterecomponent', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
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
	cmd_create_user=new RegExp('@' + process.env.HUBOT_NAME + ' create user (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_create_user
		(msg) ->
			user_name = msg.match[1];
			
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				unique_password = uniqueId(5);
				if stdout.udeploycreatereuser.workflowflag == true
					generate_id.getNextSequence (err,id) ->	
						tckid=id
						#Set APPROVAL_APP_URL
						payload={botname:process.env.HUBOT_NAME,user_name:user_name,username:msg.message.user.name,userid:msg.message.room,approver:stdout.udeploycreatereuser.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'udeploycreatereuser',tckid:tckid};
						data = {"channel": stdout.udeploycreatereuser.admin,"text":"Request from"+payload.username+"Approve Request for create user","message":"Approve Request for create user",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'udeploycreatereuser',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						
						msg.send 'Your request is waiting for approval from '.concat(stdout.udeploycreatereuser.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				else
					create_user.create_user user_name, unique_password, udeploy_url, udeploy_user_id, udeploy_password, (error, stdout, stderr) ->
						if error == "null"
							msg.send stdout;
							setTimeout (->index.passData stdout),1000
							message = msg.match[0];
							actionmsg = 'u-Deploy user(s) created'
							statusmsg = 'Success';
							index.wallData botname, message, actionmsg, statusmsg;
						else
							msg.send error;
							setTimeout (->index.passData error),1000
	)
	robot.router.post '/udeploycreatereuser', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
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
	cmd_delete_user=new RegExp('@' + process.env.HUBOT_NAME + ' delete user (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_delete_user
		(msg) ->
			user_name = msg.match[1];
			
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.udeploydeletereuser.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Set APPROVAL_APP_URL
						payload={botname:process.env.HUBOT_NAME,user_name:user_name,username:msg.message.user.name,userid:msg.message.room,approver:stdout.udeploydeletereuser.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'udeploydeletereuser',tckid:tckid};
						data = {"channel": stdout.udeploydeletereuser.admin,"text":"Request from"+payload.username+"Approve Request for delete user","message":"Approve Request for delete user",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'udeploydeletereuser',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						
						msg.send 'Your request is waiting for approval from '.concat(stdout.udeploydeletereuser.admin);
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
	)
	robot.router.post '/udeploydeletereuser', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
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
	cmd_view_user=new RegExp('@' + process.env.HUBOT_NAME + ' view user (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_view_user
		(msg) ->
			user_name = msg.match[1];
			
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.udeployshowreuser.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Set APPROVAL_APP_URL
						payload={botname:process.env.HUBOT_NAME,user_name:user_name,username:msg.message.user.name,userid:msg.message.room,approver:stdout.udeployshowreuser.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'udeployshowreuser',tckid:tckid};
						data = {"channel": stdout.udeployshowreuser.admin,"text":"Request from"+payload.username+"Approve Request for view user","message":"Approve Request for view user",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'udeployshowreuser',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						
						msg.send 'Your request is waiting for approval from '.concat(stdout.udeployshowreuser.admin);
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
	)
	
	robot.router.post '/udeployshowreuser', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
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
	cmd_create_security_token=new RegExp('@' + process.env.HUBOT_NAME + ' create security token')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_create_security_token
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.udeploycreatetoken.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Set APPROVAL_APP_URL
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.udeploycreatetoken.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'udeploycreatetoken',tckid:tckid};
						data = {"channel": stdout.udeploycreatetoken.admin,"text":"Request from"+payload.username+"Approve Request for create security token","message":"Approve Request for create security token",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'udeploycreatetoken',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						
						msg.send 'Your request is waiting for approval from '.concat(stdout.udeploycreatetoken.admin);
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
	)
	robot.router.post '/udeploycreatetoken', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
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
	cmd_deploy=new RegExp('@' + process.env.HUBOT_NAME + ' deploy (.*) process (.*) env (.*) version (.*) component (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_deploy
		(msg) ->
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
						#Set APPROVAL_APP_URL
						payload={botname:process.env.HUBOT_NAME,app_name:app_name,app_process:app_process,env:env,version:version,component:component,username:msg.message.user.name,userid:msg.message.room,approver:stdout.udeployappdeploy.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'udeployappdeploy',tckid:tckid};
						data = {"channel": stdout.udeployappdeploy.admin,"text":"Request from"+payload.username+"Approve Request for deploy","message":"Approve Request for deploy",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'udeployappdeploy',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}

						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},

							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						
						msg.send 'Your request is waiting for approval from '.concat(stdout.udeployappdeploy.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert

				else
					msg.reply 'Your process is in progress. Once it\'s done you\'ll be notified.';
					app_deploy.app_deploy udeploy_url, udeploy_user_id, udeploy_password, app_name, app_process, env, version, component, (error, stdout, stderr) ->
						if error == "null"
							options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: stdout
							}
							request.post options, (err,response,body) ->
								console.log response.body
						else
							msg.send error;
	)
	
	robot.router.post '/udeployappdeploy', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			robot.messageRoom data_http.userid, 'Your request is approved by '.concat(data_http.approver);
			app_deploy.app_deploy udeploy_url, udeploy_user_id, udeploy_password, data_http.app_name, data_http.app_process, data_http.env, data_http.version, data_http.component, (error, stdout, stderr) ->
				if error == "null"
					setTimeout (->index.passData stdout),1000
					message = 'deployed '+data_http.app_name+'process '+data_http.app_process+'env '+data_http.env+'version '+data_http.version+'component '+data_http.component;
					actionmsg = 'u-Deploy application deployed';
					statusmsg = 'Success';
					index.wallData botname, message, actionmsg, statusmsg;
					options = {
					url: process.env.MATTERMOST_INCOME_URL,
					method: "POST",
					header: {"Content-type":"application/json"},
					json: stdout
					}
					request.post options, (err,response,body) ->
						console.log response.body
				else
					setTimeout (->index.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			robot.messageRoom data_http.userid, 'Your request for deploy was rejected';
