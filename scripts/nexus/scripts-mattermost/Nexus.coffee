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

#Set of bot commands for nexus
#to create new nexus repository: create nexus repo test1
#to get details of repository:  print nexus repo test1
#to get list of all repositories: list nexus repos
#to create user with specific role: create nexus user testuser1 with any-all-view role
#to get details of user: print nexus user testuser1@cognizant.com
#to get list of all users: list nexus users
#to delete a nexus user: delete nexus user testuser1@cognizant.com
#to delete a nexus repository: delete nexus repo test1
#Env variables to set:
#	NEXUS_URL
#	NEXUS_USER_ID
#	NEXUS_PASSWORD
#	HUBOT_NAME
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


nexus_url = process.env.NEXUS_URL
nexus_user_id = process.env.NEXUS_USER_ID
nexus_password =  process.env.NEXUS_PASSWORD
botname = process.HUBOT_NAME
pod_ip = process.env.MY_POD_IP;

create_repo = require('./create_repo.js');
delete_repo = require('./delete_repo.js');
create_user = require('./create_user.js');
get_all_repo = require('./get_all_repo.js');
get_given_repo = require('./get_given_repo.js');
get_all_user = require('./get_all_user.js');
get_all_privileges = require('./get_all_privileges.js');
get_given_privileges = require('./get_given_privileges.js');
create_privilege = require('./create_privilege.js');
get_privileges_details = require('./get_privileges_details.js');
get_given_user = require('./get_given_user.js');
delete_user = require('./delete_user.js');
request = require('request');

readjson = require './readjson.js'
generate_id = require('./mongoConnt')
index = require('./index.js')

uniqueId = (length=8) ->
  id = ""
  id += Math.random().toString(36).substr(2) while id.length < length
  id.substr 0, length

module.exports = (robot) ->
	cmd = new RegExp('@' + process.env.HUBOT_NAME + ' help')
	robot.hear cmd, (msg) ->
		dt = 'list nexus repos\nlist nexus users\nlist nexus repo <repo-id>\nlist nexus user <user-id>\ncreate nexus repo <repo-name>\ndelete nexus repo <repo-id>\ncreate nexus user <user-name> with <role-name> role\nshow artifacts in <groupId>\ndelete nexus user <user-id>\nlist nexus privileges\ncreate privilege <privilege name> <tagged repo id>';
		msg.send dt
		setTimeout (->index.passData dt),1000
	
	robot.router.post '/createnexusrepo', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			create_repo.repo_create nexus_url, nexus_user_id, nexus_password, data_http.repoid, data_http.repo_name, (error, stdout, stderr) ->
				if error == null
					dt = 'Nexus repo created with ID : '.concat(data_http.repoid)
					setTimeout (->index.passData dt),1000
					actionmsg = 'Nexus repo created with ID : '.concat(data_http.repoid);
					statusmsg = 'Success'
					index.wallData botname, data_http.message, actionmsg, statusmsg;
					robot.messageRoom data_http.userid, dt
				else
					setTimeout (->index.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			dt = 'You are not authorized.'
			robot.messageRoom data_http.userid, dt;
			setTimeout (->index.passData dt),1000
	cmdcreate = new RegExp('@' + process.env.HUBOT_NAME + ' create nexus repo (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreate
		(msg) ->
			message = "Nexus repo created"
			actionmsg = ""
			statusmsg = ""
			repoid = msg.match[1]
			repo_name = repoid
			unique_id = uniqueId(5);
			repoid = repoid.concat(unique_id);
						
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.createnexusrepo.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.createnexusrepo.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,repoid:repoid,repo_name:repo_name,callback_id: 'createnexusrepo',tckid:tckid};
						data = {"channel": stdout.createnexusrepo.admin,"text":"Approve Request for create nexus repo","message":"Approve Request for create nexus repo",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'createnexusrepo',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.createnexusrepo.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
					
				else
					create_repo.repo_create nexus_url, nexus_user_id, nexus_password, repoid, repo_name, (error, stdout, stderr) ->
						if error == null
							actionmsg = 'Nexus repo created with ID : '.concat(repoid);
							statusmsg= 'Success';
							msg.send 'Nexus repo created with ID : '.concat(repoid);
							setTimeout (->index.passData actionmsg),1000
							index.wallData botname, message, actionmsg, statusmsg;
						else
							msg.send error + "from repo";
							setTimeout (->index.passData message2),1000
	)
	
	robot.router.post '/deletenexusrepo', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			delete_repo.repo_delete nexus_url, nexus_user_id, nexus_password, data_http.repoid, (error, stdout, stderr) ->
				if error == null
					actionmsg = 'Nexus repo deleted with ID : '.concat(data_http.repoid);
					statusmsg = 'Success';
					index.wallData botname, data_http.message, actionmsg, statusmsg;
					robot.messageRoom data_http.userid, 'Nexus repo deleted with ID : '.concat(data_http.repoid);
					setTimeout (->index.passData actionmsg),1000
				else
					setTimeout (->index.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			dt = 'You are not authorized.'
			robot.messageRoom data_http.userid, dt;
			setTimeout (->index.passData dt),1000
	cmddelete = new RegExp('@' + process.env.HUBOT_NAME + ' delete nexus repo (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddelete
		(msg) ->
			message = "Nexus repo deleted"
			actionmsg = ""
			statusmsg = ""
			repoid = msg.match[1]
			
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.deletenexusrepo.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.deletenexusrepo.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,repoid:repoid,callback_id: 'deletenexusrepo',tckid:tckid};
						data = {"channel": stdout.deletenexusrepo.admin,"text":"Approve Request for deleting nexus repo","message":"Request to delete nexus repo with ID: "+payload.repoid,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'deletenexusrepo',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '+stdout.deletenexusrepo.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
					
				else
					delete_repo.repo_delete nexus_url, nexus_user_id, nexus_password, repoid, (error, stdout, stderr) ->
						if error == null
							actionmsg = 'Nexus repo deleted with ID : '.concat(repoid);
							statusmsg= 'Success';
							msg.send actionmsg
							index.wallData botname, message, actionmsg, statusmsg;
							setTimeout (->index.passData actionmsg),1000
						else
							msg.send error;
							setTimeout (->index.passData error),1000
	)
	robot.router.post '/listnexusreposome', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			get_given_repo.get_given_repo nexus_url, nexus_user_id, nexus_password, data_http.repoid, (error, stdout, stderr) ->
				if error == null
					setTimeout (->index.passData stdout),1000
					robot.messageRoom data_http.userid, stdout;
				else
					setTimeout (->index.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			dt = 'You are not authorized.'
			robot.messageRoom data_http.userid, dt;
			setTimeout (->index.passData dt),1000
	cmdprint = new RegExp('@' + process.env.HUBOT_NAME + ' list nexus repo (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdprint
		(msg) ->
			repoid = msg.match[1]
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.listnexusreposome.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.id,approver:stdout.listnexusreposome.admin,podIp:pod_ip,message:msg.message.text,repoid:repoid,tckid:tckid,callback_id:"listnexusreposome"}
						data={"channel": stdout.listnexusreposome.admin,"text":"Approve Request for accessing nexus repo details","message":"Request to give details of nexus repo with ID: "+payload.repoid,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'listnexusreposome',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval by '+stdout.listnexusreposome.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
					
				else
					get_given_repo.get_given_repo nexus_url, nexus_user_id, nexus_password, repoid, (error, stdout, stderr) ->
						if error == null
							msg.send stdout;
							setTimeout (->index.passData stdout),1000
						else
							msg.send error;
							setTimeout (->index.passData error),1000
	)
	robot.router.post '/listnexusrepos', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			get_all_repo.get_all_repo nexus_url, nexus_user_id, nexus_password, (error, stdout, stderr) ->
				if error == null
					setTimeout (->index.passData stdout),1000
					robot.messageRoom data_http.userid, stdout;
				else
					setTimeout (->index.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			robot.messageRoom data_http.userid, 'You are not authorized.';
	cmdlist = new RegExp('@' + process.env.HUBOT_NAME + ' list nexus repos')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdlist
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.listnexusrepos.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.listnexusrepos.admin,podIp:pod_ip,message:msg.message.text,callback_id: 'listnexusrepos',tckid:tckid};
						data = {"channel": stdout.listnexusrepos.admin,"text":"Approve Request for listing nexus repos","message":"Request to list details of all nexus repos",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'listnexusrepos',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your approval request is waiting from '.concat(stdout.listnexusrepos.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				else
					get_all_repo.get_all_repo nexus_url, nexus_user_id, nexus_password, (error, stdout, stderr) ->
						if error == null
							msg.send stdout;
							setTimeout (->index.passData stdout),1000
						else
							msg.send error;
							setTimeout (->index.passData error),1000
	)
	robot.router.post '/listnexususersome', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			get_given_user.get_given_user nexus_url, nexus_user_id, nexus_password, data_http.userid_nexus, (error, stdout, stderr) ->
				if error == null
					setTimeout (->index.passData stdout),1000
					robot.messageRoom data_http.userid, stdout;
				else
					setTimeout (->index.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			robot.messageRoom data_http.userid, 'You are not authorized.';
	cmdprintuser = new RegExp('@' + process.env.HUBOT_NAME + ' list nexus user (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdprintuser
		(msg) ->
			userid_nexus = msg.match[1]
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.listnexususersome.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.listnexususersome.admin,podIp:pod_ip,message:msg.message.text,userid_nexus:userid_nexus,callback_id: 'listnexususersome',tckid:tckid};
						data = {"channel": stdout.listnexususersome.admin,"text":"Approve Request for accessing nexus user details","message":"Request to list details of nexus user with ID: "+payload.userid_nexus,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'listnexususersome',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval by '+stdout.listnexususersome.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
						
				else
					get_given_user.get_given_user nexus_url, nexus_user_id, nexus_password, userid_nexus, (error, stdout, stderr) ->
						if error == null
							msg.send stdout;
							setTimeout (->index.passData stdout),1000
						else
							msg.send error;
							setTimeout (->index.passData error),1000
	)
	robot.router.post '/listnexususer', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			get_all_user.get_all_user nexus_url, nexus_user_id, nexus_password, (error, stdout, stderr) ->
				if error == null
					setTimeout (->index.passData stdout),1000
					robot.messageRoom data_http.userid, stdout;
				else
					setTimeout (->index.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			robot.messageRoom data_http.userid, 'You are not authorized.';
	cmdlistuser = new RegExp('@' + process.env.HUBOT_NAME + ' list nexus users')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdlistuser
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.listnexususer.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.listnexususer.admin,podIp:pod_ip,message:msg.message.text,callback_id: 'listnexususer',tckid:tckid};
						data = {"channel": stdout.listnexususer.admin,"text":"Approve Request for accessing nexus user details","message":"Request to list details of all nexus users",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'listnexususer',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval by '+stdout.listnexususer.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				else
					get_all_user.get_all_user nexus_url, nexus_user_id, nexus_password, (error, stdout, stderr) ->
						if error == null
							msg.send stdout;
							setTimeout (->index.passData stdout),1000
						else
							msg.send error;
							setTimeout (->index.passData error),1000
	)
	robot.router.post '/createnexususer', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			create_user.create_user nexus_url, nexus_user_id, nexus_password, data_http.user_id, data_http.roleid, data_http.password, (error, stdout, stderr) ->
				if error == null
					dt = 'Nexus user created with password : '.concat(data_http.password)
					setTimeout (->index.passData dt),1000
					actionmsg = 'Nexus user created';
					statusmsg = 'Success';
					robot.messageRoom data_http.userid, 'Nexus user created with password : '.concat(data_http.password);
					setTimeout (->index.passData dt),1000
					index.wallData botname, data_http.message, actionmsg, statusmsg;
				else
					setTimeout (->index.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			dt = 'You are not authorized.'
			robot.messageRoom data_http.userid, dt;
			setTimeout (->index.passData dt),1000
	cmdcreateuser = new RegExp('@' + process.env.HUBOT_NAME + ' create nexus user (.*) with (.*) role')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreateuser
		(msg) ->
			message = "Nexus user created"
			actionmsg = ""
			statusmsg = ""
			user_id = msg.match[1]
			roleid = msg.match[2]
			password = uniqueId(8);
			
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.createnexususer.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.createnexususer.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,user_id:user_id,roleid:roleid,password:password,callback_id: 'createnexususer',tckid:tckid};
						data = {"channel": stdout.createnexususer.admin,"text":"Request from "+payload.username+" to create nexus user","message":"Request to create nexus user with role: "+payload.roleid,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'createnexususer',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '+stdout.createnexususer.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
						
				else
					create_user.create_user nexus_url, nexus_user_id, nexus_password, user_id, roleid, password, (error, stdout, stderr) ->
						if error == null
							dt = 'Nexus user created with password : '.concat(stdout.password)
							actionmsg = 'Nexus user created';
							statusmsg= 'Success';
							robot.messageRoom msg.message.user.id, dt
							index.wallData botname, message, actionmsg, statusmsg;
							setTimeout (->index.passData dt),1000
						else
							msg.send error;
							setTimeout (->index.passData error),1000
	)
	robot.router.post '/deletenexususer', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			delete_user.delete_user nexus_url, nexus_user_id, nexus_password, data_http.user_id, (error, stdout, stderr) ->
				if error == null
					actionmsg = 'Nexus user deleted'
					statusmsg = 'Success';
					dt='Nexus user deleted with ID : '.concat(data_http.user_id)
					robot.messageRoom data_http.userid, dt;
					setTimeout (->index.passData dt),1000
					index.wallData botname, data_http.message, actionmsg, statusmsg;
				else
					setTimeout (->index.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			dt = 'You are not authorized.'
			robot.messageRoom data_http.userid, dt;
			setTimeout (->index.passData dt),1000
	cmddeleteuser = new RegExp('@' + process.env.HUBOT_NAME + ' delete nexus user (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddeleteuser
		(msg) ->
			message = "Nexus user deleted"
			actionmsg = ""
			statusmsg = ""
			user_id = msg.match[1]
		
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.deletenexususer.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.deletenexususer.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,user_id:user_id,callback_id: 'deletenexususer',tckid:tckid};
						data = {"channel": stdout.deletenexususer.admin,"text":"Approve Request for deleting nexus user","message":"Request to delete nexus user with name: "+payload.user_id,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'deletenexususer',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '+stdout.deletenexususer.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
					
				else
					delete_user.delete_user nexus_url, nexus_user_id, nexus_password, user_id, (error, stdout, stderr) ->
						if error == null
							actionmsg = 'Nexus user deleted'
							statusmsg= 'Success';
							dt='Nexus user deleted with ID : '.concat(user_id);
							msg.send dt
							setTimeout (->index.passData dt),1000
							index.wallData botname, message, actionmsg, statusmsg;
						else
							msg.send error;
							setTimeout (->index.passData error),1000
	)
	robot.router.post '/listnexusprivilege', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			get_all_privileges.get_all_privileges nexus_url, nexus_user_id, nexus_password, (error, stdout, stderr) ->
				if error == null
					setTimeout (->index.passData stdout),1000
					robot.messageRoom data_http.userid, stdout;
				else
					setTimeout (->index.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			robot.messageRoom data_http.userid, 'You are not authorized.';
	cmdlistpriv = new RegExp('@' + process.env.HUBOT_NAME + ' list nexus privileges')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdlistpriv
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.listnexusprivilege.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.id,approver:stdout.listnexusprivilege.admin,podIp:pod_ip,message:msg.message.text,callback_id: 'listnexusprivilege',tckid:tckid};
						data = {"channel": stdout.listnexusprivilege.admin,"text":"Approve Request for accessing nexus privilege details","message":"Request to access all nexus privilege details",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'listnexusprivilege',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval by '+stdout.listnexusprivilege.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				
				else
					get_all_privileges.get_all_privileges nexus_url, nexus_user_id, nexus_password, (error, stdout, stderr) ->
						if error == null
							msg.send stdout;
							setTimeout (->index.passData stdout),1000
						else
							msg.send error;
							setTimeout (->index.passData error),1000
	)
	cmdgetpriv = new RegExp('@' + process.env.HUBOT_NAME + ' get nexus privilege (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdgetpriv
		(msg) ->
			userid = msg.match[1]
			get_given_privileges.get_given_privileges nexus_url, nexus_user_id, nexus_password, userid, (error, stdout, stderr) ->
				if error == null
					setTimeout (->index.passData stdout),1000
					msg.send stdout;
				else
					setTimeout (->index.passData error),1000
					msg.send error;
	)
	cmdsearch = new RegExp('@' + process.env.HUBOT_NAME + ' search pri name (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdsearch
		(msg) ->
			name = msg.match[1]
			msg.send name
			get_privileges_details.get_privileges_details nexus_url, nexus_user_id, nexus_password, name, (error, stdout, stderr) ->
				if error == null
					setTimeout (->index.passData stdout),1000
					msg.send stdout;
				else
					setTimeout (->index.passData error),1000
					msg.send error;
	)
	robot.router.post '/createnexusprivilege', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			create_privilege.create_privilege nexus_url, nexus_user_id, nexus_password, data_http.pri_name, data_http.repo_id, (error, stdout, stderr) ->
				if error == null
					dt = stdout.concat(' with name : ').concat(data_http.pri_name).concat(' tagged with repo : ').concat(data_http.repo_id)
					setTimeout (->index.passData dt),1000
					actionmsg = 'Nexus privilege(s) created'
					statusmsg = 'Success'
					index.wallData botname, data_http.message, actionmsg, statusmsg;
					robot.messageRoom data_http.userid, stdout.concat(' with name : ').concat(data_http.pri_name).concat(' tagged with repo : ').concat(data_http.repo_id);
				else
					setTimeout (->index.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			dt = 'You are not authorized.'
			robot.messageRoom data_http.userid, dt;
			setTimeout (->index.passData dt),1000
	cmdcreatepriv = new RegExp('@' + process.env.HUBOT_NAME + ' create privilege (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreatepriv
		(msg) ->
			array_command = msg.match[1].split " ", 2
			pri_name = array_command[0]
			repo_id = array_command[1]
			message = "Nexus privilege(s) created"
			
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.createnexusprivilege.workflowflag == true
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.createnexusprivilege.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,repo_id:repo_id,pri_name:pri_name,callback_id: 'createnexusprivilege',tckid:tckid};
						data = {"channel": stdout.createnexusprivilege.admin,"text":"Approve Request for creating nexus privilege","message":"Request to create nexus privilege with name: "+payload.pri_name,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'createnexusprivilege',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '+stdout.createnexusprivilege.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				else
					create_privilege.create_privilege nexus_url, nexus_user_id, nexus_password, pri_name, repo_id, (error, stdout, stderr) ->
						if error == null
							dt = stdout.concat(' with name : ').concat(pri_name).concat(' tagged with repo : ').concat(repo_id);
							msg.send dt
							actionmsg = 'Nexus privilege(s) created'
							statusmsg = 'Success'
							index.wallData botname, message, actionmsg, statusmsg;
							setTimeout (->index.passData dt),1000
						else
							msg.send error;
							setTimeout (->index.passData error),1000
	)
	cmdartifacts = new RegExp('@' + process.env.HUBOT_NAME + ' show artifacts in (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdartifacts
		(msg) ->
			url=nexus_url+'/service/local/lucene/search?g='+msg.match[1]+''
			options = {
			auth: {
			'user': nexus_user_id,
			'pass': nexus_password
			},
			method: 'GET',
			url: url
			}
			request options, (error, response, body) ->
				result = body.split('<artifact>')
				if(result.length==1)
					dt = 'No artifacts found for groupId: '+msg.match[1]
				else
					dt = '*No.*\t\t\t*Group Id*\t\t\t*Artifact Id*\t\t\t*Version*\t\t\t\t*RepoId*\n'
					for i in [1...result.length]
						if(result[i].indexOf('latestReleaseRepositoryId')!=-1)
							dt = dt + i+'\t\t\t'+result[i].split('<groupId>')[1].split('</groupId>')[0]+'\t\t'+result[i].split('<artifactId>')[1].split('</artifactId>')[0]+'\t\t'+result[i].split('<version>')[1].split('</version>')[0]+'\t\t'+result[i].split('<latestReleaseRepositoryId>')[1].split('</latestReleaseRepositoryId>')[0]+'\n'
						else
							dt = dt + i+'\t\t\t'+result[i].split('<groupId>')[1].split('</groupId>')[0]+'\t\t'+result[i].split('<artifactId>')[1].split('</artifactId>')[0]+'\t\t'+result[i].split('<version>')[1].split('</version>')[0]+'\t\t'+result[i].split('<latestSnapshotRepositoryId>')[1].split('</latestSnapshotRepositoryId>')[0]+'\n'
				msg.send dt
				setTimeout (->index.passData dt),1000
	)
