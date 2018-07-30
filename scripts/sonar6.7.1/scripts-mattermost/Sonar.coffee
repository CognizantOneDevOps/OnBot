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
1. Creation and Deletion of Project/User
2. Grant and Revoke Permissions from User

Example bot commands
1. create sonar user test1
2. delete sonar user test1
3. create sonar project testproj
4. delete sonar project testproj
5. grant sonar user access for user test1 to project testproj

Environment variables to set:
1. SONAR_URL
2. SONAR_USER_ID
3. SONAR_PASSWORD
4. HUBOT_NAME
###

#Load Dependencies
eindex = require('./index')
request = require('request')
readjson = require ('./readjson.js');
create_project = require('./create_project.js');
delete_project = require('./delete_project.js');
create_user = require('./create_user.js');
delete_user = require('./delete_user.js');
grant_user = require('./grant_user.js');
revoke_user = require('./revoke_user.js');
list_project = require('./list_project.js');
list_user = require('./list_user.js');
generate_id = require('./mongoConnt');
#Required Environment Variables
sonar_url = process.env.SONAR_URL
sonar_user_id = process.env.SONAR_USER_ID
sonar_password =  process.env.SONAR_PASSWORD
botname = process.env.HUBOT_NAME
pod_ip = process.env.MY_POD_IP

module.exports = (robot) ->
	cmdhelp = new RegExp('@' + process.env.HUBOT_NAME + ' help')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdhelp
		(msg) ->
			msg.send "getMetrics <projectname>\ncreate sonar project <project-id>\nlist sonar projects\nlist sonar users\ndelete sonar user <user-id>\ncreate sonar user <user-id>\ndelete sonar project <project-id>\ngrant sonar <permission-name> <userid> <projectKey>\nrevoke sonar <permission-name> <userid> <projectKey>\nHere are some possible project permissions in sonar: **admin, codeviewer, issueadmin, scan, user** etc]"
	)
	
	cmdcreateproj = new RegExp('@' + process.env.HUBOT_NAME + ' create sonar project (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreateproj
		(msg) ->
			message = msg.match[0]
			projectid = msg.match[1]
			user = msg.message.user.name
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				#Action Flow with workflow flag
				if stdout.sonarcreateproject.workflowflag == true
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.sonarcreateproject.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,projectid:projectid,callback_id: 'sonarcreateproject',tckid:tckid};
						data = {"channel": stdout.sonarcreateproject.admin,"text":"Request from " + payload.username + " for creating sonar project with ID: "+payload.projectid,"message":"Request from " + payload.username + " to create sonar project with ID: "+payload.projectid,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'sonarcreateproject',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							msg.send 'Your request is waiting for approval from '+stdout.sonarcreateproject.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Casual workflow
				else
					create_project.create_project sonar_url, sonar_user_id, sonar_password, projectid, (error, stdout, stderr) ->
						if stdout == 'Created successfully'
							finalmsg = 'Sonar project created with ID : '.concat(projectid);
							# Send data to elastic search for logs
							setTimeout (->eindex.passData finalmsg),1000
							msg.send finalmsg;
							# Send data for wall notification and call from file hubot-elasticsearch-logger/index.js
							actionmsg = 'Sonar project created';
							statusmsg = 'Success';
							eindex.wallData botname, message, actionmsg, statusmsg;
						else if error
							setTimeout (->eindex.passData error),1000
							msg.send error
						else if stderr
							setTimeout (->eindex.passData stderr),1000
							msg.send stderr
	)
	#Approval Workflow
	robot.router.post '/sonarcreateproject', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' for the creation of project';
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			projectid = request.body.projectid;
			# Call from create_project file for project creation 
			create_project.create_project sonar_url, sonar_user_id, sonar_password, projectid, (error, stdout, stderr) ->
				if stdout == 'Created successfully'
					finalmsg = 'Sonar project created with ID : '.concat(projectid);
					# Send data to elastic search for logs
					setTimeout (->eindex.passData finalmsg),1000
					robot.messageRoom data_http.userid, finalmsg;
					# Send data to elastic search for wall notification
					message = 'create sonar project '+ projectid;
					actionmsg = 'Sonar project created';
					statusmsg = 'Success';
					eindex.wallData botname, message, actionmsg, statusmsg;
				# Error and Exception handled
				else if error
					setTimeout (->eindex.passData error),1000
					robot.messageRoom data_http.userid, error
				else if stderr
					setTimeout (->eindex.passData stderr),1000
					robot.messageRoom data_http.userid, stderr
		else
			dt="Create sonar project request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to create project.';
	
	cmdlistproj = new RegExp('@' + process.env.HUBOT_NAME + ' list sonar projects')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdlistproj
		(msg) ->
			projectid = msg.match[1]
			# Call from list_project file to list available project 
			list_project.list_project sonar_url, sonar_user_id, sonar_password, projectid, (error, stdout, stderr) ->
				if stdout
					# Send data to elastic search for logs
					setTimeout (->eindex.passData stdout),1000
					msg.send stdout;
				else if error
					setTimeout (->eindex.passData error),1000
					msg.send error
				else if stderr
					setTimeout (->eindex.passData stderr),1000
					msg.send stderr
	)
	
	cmdlistuser = new RegExp('@' + process.env.HUBOT_NAME + ' list sonar users')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdlistuser
		(msg) ->
			projectid = msg.match[1]
			# Call from list_user file to list available users 
			list_user.list_user sonar_url, sonar_user_id, sonar_password, projectid, (error, stdout, stderr) ->
				if stdout
					# Send data to elastic search for logs
					setTimeout (->eindex.passData stdout),1000
					msg.send stdout;
				# Exception and Error Handled
				else if error
					setTimeout (->eindex.passData error),1000
					msg.send error
				else if stderr
					setTimeout (->eindex.passData stderr),1000
					msg.send stderr
	)
	
	cmddeleteuser = new RegExp('@' + process.env.HUBOT_NAME + ' delete sonar user (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddeleteuser
		(msg) ->
			message = msg.match[0]
			userids = msg.match[1]
			user = msg.message.user.name
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				#Action Flow with workflow flag
				if stdout.sonardeleteuser.workflowflag == true
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.sonardeleteuser.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,userids:userids,callback_id: 'sonardeleteuser',tckid:tckid};
						data = {"channel": stdout.sonardeleteuser.admin,"text":"Request from " + payload.username + " for deleting sonar user with ID: "+ payload.userids,"message":"Request from " + payload.username + " to delete sonar user with ID: "+payload.userids,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'sonardeleteuser',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url":process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							msg.send 'Your request is waiting for approval from '+stdout.sonardeleteuser.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Casual workflow
				else
					delete_user.delete_user sonar_url, sonar_user_id, sonar_password, userids, (error, stdout, stderr) ->
						if stdout == 'user deleted'
							finalmsg = 'User deleted with ID : '.concat(userids);
							# Send data to elastic search for logs
							setTimeout (->eindex.passData finalmsg),1000
							msg.send finalmsg;
							actionmsg = 'Sonar user deleted';
							statusmsg = 'Success';
							eindex.wallData botname, message, actionmsg, statusmsg;
						else if error
							setTimeout (->eindex.passData error),1000
							msg.send error
						else if stderr
							setTimeout (->eindex.passData stderr),1000
							msg.send stderr
	)
	#Approval Workflow
	robot.router.post '/sonardeleteuser', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		console.log(data_http)
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' for the deletion of user'
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			userids = request.body.userids;
			# Call from delete_user file to delete user
			delete_user.delete_user sonar_url, sonar_user_id, sonar_password, userids, (error, stdout, stderr) ->
				if stdout == 'user deleted'
					finalmsg = 'User deleted with ID : '.concat(userids);
					# Send data to elastic search for logs
					setTimeout (->eindex.passData finalmsg),1000
					robot.messageRoom data_http.userid, finalmsg;
					# Send data to elastic search for wall notification
					message = 'delete sonar user '+ userids;
					actionmsg = 'Sonar user deleted';
					statusmsg = 'Success';
					eindex.wallData botname, message, actionmsg, statusmsg;
				else if error
					setTimeout (->eindex.passData error),1000
					robot.messageRoom data_http.userid, error;
				else if stderr
					setTimeout (->eindex.passData stderr),1000
					robot.messageRoom data_http.userid, stderr;
		else
			dt="Delete Sonar User request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to delete user.';
	
	cmdcreateuser = new RegExp('@' + process.env.HUBOT_NAME + ' create sonar user (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreateuser
		(msg) ->
			message = msg.match[0]
			userids = msg.match[1]
			user = msg.message.user.name
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.sonarcreateuser.workflowflag == true
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.sonarcreateuser.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,userids:userids,callback_id: 'sonarcreateuser',tckid:tckid};
						data = {"channel": stdout.sonarcreateuser.admin,"text":"Request from " + payload.username + " for creating sonar user with ID: "+ payload.userids,"message":"Request from " + payload.username + " to create sonar user with ID: "+payload.userids,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'sonarcreateuser',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							msg.send 'Your request is waiting for approval from '+stdout.sonarcreateuser.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Casual workflow
				else
					create_user.create_user sonar_url, sonar_user_id, sonar_password, userids, (error, stdout, stderr) ->
						if stdout == 'user created'
							finalmsg = 'User created with ID and password:  '.concat(userids);
							# Send data to elastic search for logs
							setTimeout (->eindex.passData finalmsg),1000
							msg.send finalmsg;
							# Send data to elastic search for wall notification
							actionmsg = 'Sonar user created';
							statusmsg = 'Success';
							eindex.wallData botname, message, actionmsg, statusmsg;
						else if error
							setTimeout (->eindex.passData error),1000
							msg.send error;
						else if stderr
							setTimeout (->eindex.passData stderr),1000
							msg.send stderr;
	)
	#Approval Workflow
	robot.router.post '/sonarcreateuser', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		console.log(data_http)
		if data_http.action == "Approve"
			dt="Create Sonar User request is approved by "+data_http.approver
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			userids = request.body.userids;
			# Call from create_user file to create user
			create_user.create_user sonar_url, sonar_user_id, sonar_password, userids, (error, stdout, stderr) ->
				if stdout == 'user created'
					finalmsg = 'User created with ID and password:  '.concat(userids);
					# Send data to elastic search for logs
					setTimeout (->eindex.passData finalmsg),1000
					robot.messageRoom data_http.userid, finalmsg;
					message = 'create sonar user '+ userids;
					actionmsg = 'Sonar user created';
					statusmsg = 'Success';
					eindex.wallData botname, message, actionmsg, statusmsg;
				else if error
					setTimeout (->eindex.passData error),1000
					robot.messageRoom data_http.userid, error
				else if stderr
					setTimeout (->eindex.passData stderr),1000
					robot.messageRoom data_http.userid, stderr
		else
			dt="Create Sonar User request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to create user.';
	
	cmddeleteproject = new RegExp('@' + process.env.HUBOT_NAME + ' delete sonar project (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddeleteproject
		(msg) ->
			message = msg.match[0]
			projectid = msg.match[1]
			user = msg.message.user.name
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.sonardeleteproject.workflowflag == true
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.sonardeleteproject.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,projectid:projectid,callback_id: 'sonardeleteproject',tckid:tckid};
						data = {"channel": stdout.sonardeleteproject.admin,"text":"Request from " + payload.username + " for deleting sonar project with ID: "+payload.projectid,"message":"Request from " + payload.username + " to delete sonar project with ID: "+payload.projectid,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'sonardeleteproject',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							msg.send 'Your request is waiting for approval from '+stdout.sonardeleteproject.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Casual workflow
				else
					delete_project.delete_project sonar_url, sonar_user_id, sonar_password, projectid, (error, stdout, stderr) ->
						if stdout == 'Deleted successfully'
							finalmsg = 'Sonar project deleted with id : '.concat(projectid);
							# Send data to elastic search for logs
							setTimeout (->eindex.passData finalmsg),1000
							msg.send finalmsg;
							# Send data to elastic search for wall notification
							actionmsg = 'Sonar project deleted';
							statusmsg = 'Success';
							eindex.wallData botname, message, actionmsg, statusmsg;
						else if error
							setTimeout (->eindex.passData error),1000
							msg.send error
						else if stderr
							setTimeout (->eindex.passData stderr),1000
							msg.send stderr
	)
	#Approval Workflow
	robot.router.post '/sonardeleteproject', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		console.log(data_http)
		if data_http.action == "Approve"
			dt="Delete Sonar Project request is approved by "+data_http.approver
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			projectid = request.body.projectid;
			# Call from delete_project file for the deletion of project
			delete_project.delete_project sonar_url, sonar_user_id, sonar_password, projectid, (error, stdout, stderr) ->
				if stdout == 'Deleted successfully'
					finalmsg = 'Sonar project deleted with id : '.concat(projectid);
					# Send data to elastic search for logs
					setTimeout (->eindex.passData finalmsg),1000
					robot.messageRoom data_http.userid, finalmsg;
					# Send data to elastic search for wall notification
					message = 'delete sonar project '+ projectid;
					actionmsg = 'Sonar project deleted';
					statusmsg = 'Success';
					eindex.wallData botname, message, actionmsg, statusmsg;
				else if error
					setTimeout (->eindex.passData error),1000
					robot.messageRoom data_http.userid, error
				else if stderr
					setTimeout (->eindex.passData stderr),1000
					robot.messageRoom data_http.userid, stderr
		else
			dt="Delete Sonar Project request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to delete project.';
	
	cmdgrant = new RegExp('@' + process.env.HUBOT_NAME + ' grant sonar (.*)$')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdgrant
		(msg) ->
			message = msg.match[0]
			split_string = msg.match[1].split " ", 3
			perm = split_string[0].trim()
			userids = split_string[1].trim()
			projid = split_string[2].trim()
			user = msg.message.user.name
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.grantsonar.workflowflag == true
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.grantsonar.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,userids:userids,callback_id: 'grantsonar',tckid:tckid,perm:perm,projid:projid};
						data = {"channel": stdout.grantsonar.admin,"text":"Request from " + payload.username + " for granting permissions to sonar user with ID: "+payload.userids,"message":"Request from " + payload.username + " to grant permissions to sonar user with ID: "+payload.userids,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'grantsonar',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							msg.send 'Your request is waiting for approval from '+stdout.grantsonar.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Casual workflow
				else
					grant_user.grant_user sonar_url, sonar_user_id, sonar_password, perm, projid, userids, (error, stdout, stderr) ->
						if stdout == ''
							finalmsg = 'Granted permission : '.concat(perm).concat(' for user : ').concat(userids).concat(' for project : ').concat(projid);
							# Send data to elastic search for logs
							setTimeout (->eindex.passData finalmsg),1000
							msg.send finalmsg;
							# Send data to elastic search for wall notification
							actionmsg = 'Permissions granted to sonar user';
							statusmsg = 'Success';
							eindex.wallData botname, message, actionmsg, statusmsg;
						else if error
							setTimeout (->eindex.passData error),1000
							msg.send error
						else if stderr
							setTimeout (->eindex.passData stderr),1000
							msg.send stderr
	)
	#Approval Workflow
	robot.router.post '/grantsonar', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		console.log(data_http)
		if data_http.action == "Approve"
			dt="Grant Sonar Permissions request is approved by "+data_http.approver
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			projid = request.body.projid;
			userids = request.body.userids;
			perm = request.body.perm;
			# Call from grant_user file to grant permission to the user for particular project
			grant_user.grant_user sonar_url, sonar_user_id, sonar_password, perm, projid, userids, (error, stdout, stderr) ->
				if stdout == ''
					finalmsg = 'Granted permission : '.concat(perm).concat(' for user : ').concat(userids).concat(' for project : ').concat(projid);
					setTimeout (->eindex.passData finalmsg),1000
					robot.messageRoom data_http.userid, finalmsg;
					# Send data to elastic search for wall notification
					message = 'grant sonar '+ perm;
					actionmsg = 'Permissions granted to sonar user';
					statusmsg = 'Success';
					eindex.wallData botname, message, actionmsg, statusmsg;
				else if error
					setTimeout (->eindex.passData error),1000
					robot.messageRoom data_http.userid, error
				else if stderr
					setTimeout (->eindex.passData stderr),1000
					robot.messageRoom data_http.userid, stderr
		else
			dt="Grant Sonar Permissions request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to grant permissions.';
	
	cmdrevoke = new RegExp('@' + process.env.HUBOT_NAME + ' revoke sonar (.*)$')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdrevoke
		(msg) ->
			message = msg.match[0]
			split_string = msg.match[1].split " ", 3
			perm = split_string[0].trim()
			userids = split_string[1].trim()
			projid = split_string[2].trim()
			user = msg.message.user.name
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.revokesonar.workflowflag == true
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.revokesonar.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,userids:userids,callback_id: 'revokesonar',tckid:tckid,perm:perm,projid:projid};
						data = {"channel": stdout.revokesonar.admin,"text":"Request from " + payload.username + " for revoking sonar project with ID: "+payload.userids,"message":"Request from " + payload.username + " to delete sonar project with ID: "+payload.userids,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'revokesonar',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							msg.send 'Your request is waiting for approval from '+stdout.revokesonar.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Casual workflow
				else
					revoke_user.revoke_user sonar_url, sonar_user_id, sonar_password, perm, projid, userids, (error, stdout, stderr) ->
						if stdout == ''
							finalmsg = 'Revoked permission : '.concat(perm).concat(' for user : ').concat(userids).concat(' for project : ').concat(projid);
							# Send data to elastic search for logs
							setTimeout (->eindex.passData finalmsg),1000
							msg.send finalmsg;
							# Send data to elastic search for wall notification
							actionmsg = 'Pemissions revoked from sonar user';
							statusmsg = 'Success';
							eindex.wallData botname, message, actionmsg, statusmsg;
						else if error
							setTimeout (->eindex.passData error),1000
							msg.send error
						else if stderr
							setTimeout (->eindex.passData stderr),1000
							msg.send stderr
	)
	#Approval Workflow
	robot.router.post '/revokesonar', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		console.log(data_http)
		if data_http.action == "Approve"
			dt="Revoke Sonar Permissions request is approved by "+data_http.approver
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			projid = request.body.projid;
			userids = request.body.userids;
			perm = request.body.perm;
			# Call from revoke_user file to revoke permission from the user for particular project
			revoke_user.revoke_user sonar_url, sonar_user_id, sonar_password, perm, projid, userids, (error, stdout, stderr) ->
				if stdout == ''
					finalmsg = 'Revoked permission : '.concat(perm).concat(' for user : ').concat(userids).concat(' for project : ').concat(projid);
					# Send data to elastic search for logs
					setTimeout (->eindex.passData finalmsg),1000
					robot.messageRoom data_http.userid, finalmsg;
					# Send data to elastic search for wall notification
					message = 'revoke sonar '+ perm;
					actionmsg = 'Pemissions revoked from sonar user';
					statusmsg = 'Success';
					wallData.wallData botname, message, actionmsg, statusmsg;
				else if error
					setTimeout (->eindex.passData error),1000
					robot.messageRoom data_http.userid, error
				else if stderr
					setTimeout (->eindex.passData stderr),1000
					robot.messageRoom data_http.userid, stderr
		else
			dt="Revoke Sonar Permissions request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to revoke permissions.';
	cmdmetrics = new RegExp('@'+process.env.HUBOT_NAME+' getMetrics (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdmetrics
		(msg) ->
			project = msg.match[1]
			request.get sonar_url+'api/projects/search', (error, response, body) ->
			if error
				console.log error
				dt = "Error! Please check logs."
				msg.send dt
				setTimeout (->eindex.passData dt),1000
			else
				body=JSON.parse(body)
				for i in [0... body.length]
					if body.components[i].name == project
						url = sonar_url+'api/measures/search_history?component='+body.components[i].key+'&metrics=ncloc,sqale_index,duplicated_lines_density,coverage,bugs,code_smells,vulnerabilities'
				if url == undefined
					dt = "Project not found"
					msg.send dt
					setTimeout (->eindex.passData dt),1000
				else
					options = {
					url: url,
					method: 'GET',
					auth: {username: sonar_user_id, password: sonar_password}
					}
					request.get options, (error, response, body) ->
						if error
							msg.send error
						else
							dt = ''
							body = JSON.parse(body)
							if body.errors
								for i in [0... body.errors.length]
									msg.send body.errors[i].msg
							else
								for i in [0... body.measures.length]
									if body.measures[i].metric == 'bug'
										dt += ':beetle: '+body.measures[i].metric+": "+body.measures[i].history[body.measures[i].history.length-1].value+"\n"
									else if body.measures[i].metric == 'code_smells'
										dt += ':radioactive: '+body.measures[i].metric+": "+body.measures[i].history[body.measures[i].history.length-1].value+"\n"
									else if body.measures[i].metric == 'coverage'
										dt += ':o: '+body.measures[i].metric+": "+body.measures[i].history[body.measures[i].history.length-1].value+"\n"
									else if body.measures[i].metric == 'duplicated_lines_density'
										dt += ':aquarius: '+body.measures[i].metric+": "+body.measures[i].history[body.measures[i].history.length-1].value+"\n"
									else if body.measures[i].metric == 'ncloc'
										dt += ":spiral_notepad: Lines of Code: "+body.measures[i].history[body.measures[i].history.length-1].value+"\n"
									else if body.measures[i].metric == 'sqale_index'
										dt += ":woman_technologist: Technical Debt :" +body.measures[i].history[body.measures[i].history.length-1].value+"\n"
									else if body.measures[i].metric == 'vulnerabilities'
										dt += ':unlock: '+body.measures[i].metric+": "+body.measures[i].history[body.measures[i].history.length-1].value+"\n"
								msg.send dt
	)
