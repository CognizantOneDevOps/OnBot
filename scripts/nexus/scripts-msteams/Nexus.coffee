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
botname = process.BOT_NAME
pod_ip = process.env.MY_POD_IP;

create_repo = require('./create_repo.js');
delete_repo = require('./delete_repo.js');
create_user = require('./create_user.js');
get_all_repo = require('./get_all_repo.js');
get_given_repo = require('./get_given_repo.js');
get_all_user = require('./get_all_user.js');
get_all_privileges = require('./get_all_privileges.js');
get_given_privilege = require('./get_given_privilege.js');
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
  
post = (recipient, data) ->
	optons = {method: "POST", url: recipient, json: data}
	request.post optons, (error, response, body) ->
		console.log body
		
module.exports = (robot) ->
	robot.respond /help/i, (msg) ->
		dt = '<br>1) list nexus repos<br>2) list nexus users<br>3) list nexus repo <<*repo-id*>><br>4) list nexus user <<*user-id*>><br>5) create nexus repo <<*repo-name*>><br>6) delete nexus repo <<*repo-id*>><br>7) create nexus user <<*user-name*>> with <<*role-name*>> role<br>8) show artifacts in <<*groupId*>>(example com.cognizant.devops --> c*)<br>9) delete nexus user <<*user-id*>><br>10) list nexus privileges<br>11) create privilege <<*privilege name*>> <<*tagged repo id*>>';
		msg.send dt
		setTimeout (->index.passData dt),1000
	
	robot.router.post '/createnexusrepo', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		dt = {"text":" ","title":" "}
		if data_http.action == 'Approve'
			dt.title=request.body.approver+" approved nexus create repo "+request.body.repo_name+", requested by "+request.body.username+"\n"
			create_repo.repo_create nexus_url, nexus_user_id, nexus_password, data_http.repoid, data_http.repo_name, (error, stdout, stderr) ->
				if error == null
					dt.text = 'Nexus repo created with ID : '.concat(data_http.repoid)
					post data_http.userid, dt
					setTimeout (->index.passData dt),1000
					actionmsg = 'Nexus repo created'
					statusmsg = 'Success';
					dt.text = 'Nexus repo created with ID : '.concat(data_http.repoid)
					index.wallData botname, data_http.message, actionmsg, statusmsg;
					setTimeout (->index.passData dt),1000
				else
					dt.title=error
					setTimeout (->index.passData error),1000
					post data_http.userid, dt
		else
			dt.title=request.body.approver+" rejected nexus create repo "+request.body.repo_name+", requested by "+request.body.username+"\n"
			post data_http.userid, dt
			setTimeout (->index.passData dt),1000
	robot.respond /create nexus repo (.*)/i, (msg) ->
		message = msg.match[0]
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
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.createnexusrepo.admin,podIp:process.env.MY_POD_IP,repoid:repoid,repo_name:repo_name,"callback_id": 'createnexusrepo',msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Request for create nexus repo","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": 'user '+payload.username+' requested to create a repo '+payload.repoid+' '+payload.repo_name+'\n',"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approve","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}
					#Post attachment to ms teams
					post stdout.createnexusrepo.adminid, data
					msg.send 'Your request is waiting for approval by '+stdout.createnexusrepo.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				create_repo.repo_create nexus_url, nexus_user_id, nexus_password, repoid, repo_name, (error, stdout, stderr) ->
					if error == null
						actionmsg = 'Nexus repo created'
						statusmsg= 'Success';
						dt = 'Nexus repo created with ID : '.concat(repoid)
						msg.send dt
						setTimeout (->index.passData dt),1000
						index.wallData botname, message, actionmsg, statusmsg;
					else
						msg.send error;
						setTimeout (->index.passData message2),1000
	
	robot.router.post '/deletenexusrepo', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		dt = {"text":" ","title":" "}
		if data_http.action == 'Approve'
			dt.title=request.body.approver+" approved nexus delete repo "+request.body.repoid+", requested by "+request.body.username+"\n"
			delete_repo.repo_delete nexus_url, nexus_user_id, nexus_password, data_http.repoid, (error, stdout, stderr) ->
				if error == null
					dt.text = 'Nexus repo deleted with ID : '.concat(data_http.repoid)
					post data_http.userid, dt
					actionmsg = 'Nexus repo deleted'
					statusmsg = 'Success';
					index.wallData botname, data_http.message, actionmsg, statusmsg;
					setTimeout (->index.passData dt),1000
				else
					dt.title=error
					setTimeout (->index.passData error),1000
					post data_http.userid, dt
		else
			dt.title=request.body.approver+" rejected nexus delete repo "+request.body.repoid+", requested by "+request.body.username+"\n"
			post data_http.userid, dt
			setTimeout (->index.passData dt),1000
	robot.respond /delete nexus repo (.*)/i, (msg) ->
		message =msg.match[0]
		actionmsg = ""
		statusmsg = ""
		repoid = msg.match[1]
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.deletenexusrepo.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.deletenexusrepo.admin,podIp:process.env.MY_POD_IP,repoid:repoid,"callback_id": 'deletenexusrepo',msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Requested to delete nexus repo","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": 'user '+payload.username+' requested to delete a repo '+payload.repoid+'\n',"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approve","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}
					#Post attachment to ms teams
					post stdout.deletenexusrepo.adminid, data
					msg.send 'Your request is waiting for approval by '+stdout.deletenexusrepo.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
					
			else
				delete_repo.repo_delete nexus_url, nexus_user_id, nexus_password, repoid, (error, stdout, stderr) ->
					if error == null
						actionmsg = 'Nexus repo deleted'
						statusmsg= 'Success';
						dt = 'Nexus repo deleted with ID : '.concat(repoid)
						msg.send dt
						index.wallData botname, message, actionmsg, statusmsg;
						setTimeout (->index.passData dt),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
						
	robot.router.post '/listnexusreposome', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		dt = {"text":" ","title":" "}
		if data_http.action == 'Approve'
			dt.title=request.body.approver+" approved nexus list repo "+data_http.repoid+", requested by "+request.body.username+"\n"
			get_given_repo.get_given_repo nexus_url, nexus_user_id, nexus_password, data_http.repoid, (error, stdout, stderr) ->
				if error == null
					dt.text = stdout
					post data_http.userid, dt
					setTimeout (->index.passData stdout),1000
				else
					dt.title=error
					post data_http.userid, dt
					setTimeout (->index.passData error),1000
		else
			dt.title=request.body.approver+" rejected nexus list repo "+data_http.repoid+", requested by "+request.body.username+"\n"
			post data_http.userid, dt
			setTimeout (->index.passData dt),1000
	robot.respond /list nexus repo (.*)/i, (msg) ->
		repoid = msg.match[1]
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.listnexusreposome.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.listnexusreposome.admin,podIp:process.env.MY_POD_IP,repoid:repoid,"callback_id": 'listnexusreposome',msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Requested to list nexus repo","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": 'user '+payload.username+' requested to list repo '+payload.repoid+'\n',"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approve","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}
					#Post attachment to ms teams
					post stdout.listnexusreposome.adminid, data
					msg.send 'Your request is waiting for approval by '+stdout.listnexusreposome.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
					
			else
				get_given_repo.get_given_repo nexus_url, nexus_user_id, nexus_password, repoid, (error, stdout, stderr) ->
					if error == null
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
	robot.router.post '/listnexusrepos', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		dt = {"text":" ","title":" "}
		if data_http.action == 'Approve'
			dt.title=request.body.approver+" approved nexus list repos requested by "+request.body.username+"\n"
			get_all_repo.get_all_repo nexus_url, nexus_user_id, nexus_password, (error, stdout, stderr) ->
				if error == null
					dt.text=stdout
					post data_http.userid, dt
					setTimeout (->index.passData stdout),1000
				else
					dt.text=error
					post data_http.userid, dt
					setTimeout (->index.passData error),1000
		else
			dt.title=request.body.approver+" rejected nexus list repos requested by "+request.body.username+"\n"
			post data_http.userid, dt
	robot.respond /list nexus repos/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.listnexusrepos.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.listnexusrepos.admin,podIp:process.env.MY_POD_IP,'callback_id': 'listnexusrepos',msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Requested to list nexus repos","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": 'user '+payload.username+' requested to list repos '+'\n',"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approve","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}
					#Post attachment to ms teams
					post stdout.listnexusrepos.adminid, data
					msg.send 'Your request is waiting for approval by '+stdout.listnexusrepos.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
				
			else
				get_all_repo.get_all_repo nexus_url, nexus_user_id, nexus_password, (error, stdout, stderr) ->
					if error == null
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
						
	robot.router.post '/listnexususersome', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		dt = {"text":" ","title":" "}
		if data_http.action == 'Approve'
			dt.title=request.body.approver+" approved nexus list user "+data_http.userid_nexus+", requested by "+request.body.username+"\n"
			get_given_user.get_given_user nexus_url, nexus_user_id, nexus_password, data_http.userid_nexus, (error, stdout, stderr) ->
				if error == null
					dt.text=stdout
					post data_http.userid, dt
					setTimeout (->index.passData stdout),1000
				else
					dt.text=error
					post data_http.userid, dt
					setTimeout (->index.passData error),1000
		else
			dt.title=request.body.approver+" rejected nexus list user "+data_http.userid_nexus+", requested by "+request.body.username+"\n"
			post data_http.userid, dt
	robot.respond /list nexus user (.*)/i, (msg) ->
		userid_nexus = msg.match[1]
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.listnexususersome.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.listnexususersome.admin,podIp:process.env.MY_POD_IP,userid_nexus:userid_nexus,"callback_id":"listnexususersome",msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Requested to list nexus user","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": 'user '+payload.username+' requested to list user '+payload.userid_nexus+'\n',"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approve","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}
					#Post attachment to ms teams
					post stdout.listnexususersome.adminid, data
					msg.send 'Your request is waiting for approval by '+stdout.listnexususersome.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
					
			else
				get_given_user.get_given_user nexus_url, nexus_user_id, nexus_password, userid_nexus, (error, stdout, stderr) ->
					if error == null
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
						
	robot.router.post '/listnexususer', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		dt = {"text":" ","title":" "}
		if data_http.action == 'Approve'
			dt.title=request.body.approver+" approved nexus list user requested by "+request.body.username+"\n"
			get_all_user.get_all_user nexus_url, nexus_user_id, nexus_password, (error, stdout, stderr) ->
				if error == null
					dt.text=stdout
					post data_http.userid, dt
					setTimeout (->index.passData stdout),1000
				else
					dt.text=error
					post data_http.userid, dt
					setTimeout (->index.passData error),1000
		else
			dt.title=request.body.approver+" rejected nexus list user requested by "+request.body.username+"\n"
			post data_http.userid, dt
	robot.respond /list nexus users/i, (msg) ->
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.listnexususer.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.listnexususer.admin,podIp:process.env.MY_POD_IP,"callback_id":"listnexususer",msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Requested to list nexus users","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": 'user '+payload.username+' requested to list user '+'\n',"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approve","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}
					#Post attachment to ms teams
					post stdout.listnexususer.adminid, data
					msg.send 'Your request is waiting for approval by '+stdout.listnexususer.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				get_all_user.get_all_user nexus_url, nexus_user_id, nexus_password, (error, stdout, stderr) ->
					if error == null
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
						
	robot.router.post '/createnexususer', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		dt = {"text":" ","title":" "}
		if data_http.action == 'Approve'
			dt.title=request.body.approver+" approved nexus create user "+data_http.user_id+' with  '+data_http.roleid+", requested by "+request.body.username+"\n"
			create_user.create_user nexus_url, nexus_user_id, nexus_password, data_http.user_id, data_http.roleid, data_http.password, (error, stdout, stderr) ->
				if error == null
					dt.text = 'Nexus user created with password : '.concat(data_http.password)
					post data_http.userid, dt
					setTimeout (->index.passData dt),1000
					actionmsg = 'Nexus user created';
					statusmsg = 'Success';
					setTimeout (->index.passData dt),1000
					index.wallData botname, data_http.message, actionmsg, statusmsg;
				else
					dt.title=error
					post data_http.userid, dt
					setTimeout (->index.passData error),1000
		else
			dt.title=request.body.approver+" rejected nexus create user "+data_http.user_id+' with  '+data_http.roleid+", requested by "+request.body.username+"\n"
			post data_http.userid, dt
			setTimeout (->index.passData dt),1000
			
	robot.respond /create nexus user (.*) with (.*) role/i, (msg) ->
		message = msg.match[1]
		actionmsg = ""
		statusmsg = ""
		user_id = msg.match[1]
		roleid = msg.match[2]
		password = uniqueId(8);
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.createnexususer.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.createnexususer.admin,podIp:process.env.MY_POD_IP,user_id:user_id,roleid:roleid,password:password,"callback_id":"createnexususer",msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Requested to create nexus user","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": 'user '+payload.username+' requested to create a nexus user '+payload.user_id+' '+payload.roleid+'\n',"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approve","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}
					#Post attachment to ms teams
					post stdout.createnexususer.adminid, data
					msg.send 'Your request is waiting for approval by '+stdout.createnexususer.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
					
			else
				create_user.create_user nexus_url, nexus_user_id, nexus_password, user_id, roleid, password, (error, stdout, stderr) ->
					if error == null
						dt = 'Nexus user created with password : '.concat(password)
						actionmsg = 'Nexus user created';
						statusmsg= 'Success';
						msg.send dt
						index.wallData botname, message, actionmsg, statusmsg;
						setTimeout (->index.passData dt),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
						
	robot.router.post '/deletenexususer', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		dt = {"text":" ","title":" "}
		if data_http.action == 'Approve'
			dt.title=request.body.approver+" approved nexus delete user "+request.body.user_id+", requested by "+request.body.username+"\n"
			delete_user.delete_user nexus_url, nexus_user_id, nexus_password, data_http.user_id, (error, stdout, stderr) ->
				if error == null
					dt.text = 'Nexus user deleted with ID : '.concat(data_http.user_id)
					post data_http.userid, dt
					actionmsg = 'Nexus user deleted'
					statusmsg = 'Success';
					setTimeout (->index.passData dt),1000
					index.wallData botname, data_http.message, actionmsg, statusmsg;
				else
					dt.title=error
					post data_http.userid, dt
					setTimeout (->index.passData error),1000
		else
			dt.title=request.body.approver+" rejected nexus delete user "+request.body.user_id+", requested by "+request.body.username+"\n"
			post data_http.userid, dt
			setTimeout (->index.passData dt),1000
	robot.respond /delete nexus user (.*)/i, (msg) ->
		message = msg.match[0]
		actionmsg = ""
		statusmsg = ""
		user_id = msg.match[1]
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.deletenexususer.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.deletenexususer.admin,podIp:process.env.MY_POD_IP,user_id:user_id,"callback_id":"deletenexususer",msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Requested to delete a nexus user","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": 'user '+payload.username+' requested to delete a nexus user '+payload.user_id+'\n',"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approve","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}
					#Post attachment to ms teams
					post stdout.deletenexususer.adminid, data
					msg.send 'Your request is waiting for approval by '+stdout.deletenexususer.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
					
			else
				delete_user.delete_user nexus_url, nexus_user_id, nexus_password, user_id, (error, stdout, stderr) ->
					if error == null
						actionmsg = 'Nexus user deleted'
						statusmsg= 'Success';
						dt = 'Nexus user deleted with ID : '.concat(user_id)
						msg.send dt
						setTimeout (->index.passData dt),1000
						index.wallData botname, message, actionmsg, statusmsg;
					else
						msg.send error;
						setTimeout (->index.passData error),1000
						
	robot.router.post '/listnexusprivilege', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		dt = {"text":" ","title":" "}
		if data_http.action == 'Approve'
			dt.title=request.body.approver+" approved nexus list privilege "+" requested by "+request.body.username+"\n"
			get_all_privileges.get_all_privileges nexus_url, nexus_user_id, nexus_password, (error, stdout, stderr) ->
				if error == null
					dt.text=stdout
					post data_http.userid, dt
					setTimeout (->index.passData stdout),1000
				else
					dt.title=error
					post data_http.userid, dt
					setTimeout (->index.passData error),1000
		else
			dt.title=request.body.approver+" rejected nexus list privilege "+" requested by "+request.body.username+"\n"
			post data_http.userid, dt
			setTimeout (->index.passData dt),1000
	robot.respond /list nexus privileges/i, (msg) ->
	
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.listnexusprivilege.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.listnexusprivilege.admin,podIp:process.env.MY_POD_IP,"callback_id":"listnexusprivilege",msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Requested to list nexus privilege","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": 'user '+payload.username+' requested to list nexus privilege '+'\n',"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approve","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}
					#Post attachment to ms teams
					post stdout.listnexusprivilege.adminid, data
					msg.send 'Your request is waiting for approval by '+stdout.listnexusprivilege.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
	
			else
				get_all_privileges.get_all_privileges nexus_url, nexus_user_id, nexus_password, (error, stdout, stderr) ->
					if error == null
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
	robot.respond /get nexus privilege (.*)/i, (msg) ->
		userid = msg.match[1]
		get_given_privilege.get_given_privilege nexus_url, nexus_user_id, nexus_password, userid, (error, stdout, stderr) ->
			if error == null
				setTimeout (->index.passData stdout),1000
				msg.send stdout;
			else
				setTimeout (->index.passData error),1000
				msg.send error;
	robot.respond /search pri name (.*)/i, (msg) ->
		name = msg.match[1]
		msg.send name
		get_privileges_details.get_privileges_details nexus_url, nexus_user_id, nexus_password, name, (error, stdout, stderr) ->
			if error == null
				setTimeout (->index.passData stdout),1000
				msg.send stdout;
			else
				setTimeout (->index.passData error),1000
				msg.send error;
	
	robot.router.post '/createnexusprivilege', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		dt = {"text":" ","title":" "}
		if data_http.action == 'Approve'
			dt.title=request.body.approver+" approved nexus create privilege "+data_http.pri_name+' '+data_http.repo_id+", requested by "+request.body.username+"\n"
			create_privilege.create_privilege nexus_url, nexus_user_id, nexus_password, data_http.pri_name, data_http.repo_id, (error, stdout, stderr) ->
				if error == null
					dt.text=stdout.concat(' with name : ').concat(data_http.pri_name).concat(' tagged with repo : ').concat(data_http.repo_id)
					post data_http.userid, dt				
					actionmsg = 'Nexus privilege(s) created'
					statusmsg = 'Success'
					index.wallData botname, data_http.message, actionmsg, statusmsg;
					setTimeout (->index.passData dt),1000
				else
					dt.text=error
					post data_http.userid, dt
					setTimeout (->index.passData error),1000
		else
			dt.title=request.body.approver+" rejected nexus create privilege "+data_http.pri_name+' '+data_http.repo_id+", requested by "+request.body.username+"\n"
			post data_http.userid, dt
			setTimeout (->index.passData dt),1000
	
	robot.respond /create privilege (.*)/i, (msg) ->
		array_command = msg.match[1].split " ", 2
		pri_name = array_command[0]
		repo_id = array_command[1]
		message = msg.match[0]
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.createnexusprivilege.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.createnexusprivilege.admin,podIp:process.env.MY_POD_IP,repo_id:repo_id,pri_name:pri_name,"callback_id":"createnexusprivilege",msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Requested to create nexus privilege","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": 'user '+payload.username+' requested to create nexus privilege '+payload.repo_id+' '+payload.pri_name+'\n',"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approve","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}
					#Post attachment to ms teams
					post stdout.createnexusprivilege.adminid, data
					msg.send 'Your request is waiting for approval by '+stdout.createnexusprivilege.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
					
			else
				create_privilege.create_privilege nexus_url, nexus_user_id, nexus_password, pri_name, repo_id, (error, stdout, stderr) ->
					if error == null
						actionmsg = 'Nexus privilege(s) created'
						statusmsg = 'Success'
						dt = stdout.concat(' with name : ').concat(pri_name).concat(' tagged with repo : ').concat(repo_id);
						msg.send dt
						index.wallData botname, message, actionmsg, statusmsg;
						setTimeout (->index.passData dt),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
	
	robot.respond /show artifacts in (.*)/i, (msg) ->
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
				dt = '*No.* *Group Id* *Artifact Id* *Version* *RepoId*<br>'
				for i in [1...result.length]
					if(result[i].indexOf('latestReleaseRepositoryId')!=-1)
						dt = dt + i+'\t\t\t'+result[i].split('<groupId>')[1].split('</groupId>')[0]+'\t\t'+result[i].split('<artifactId>')[1].split('</artifactId>')[0]+'\t\t'+result[i].split('<version>')[1].split('</version>')[0]+'\t\t'+result[i].split('<latestReleaseRepositoryId>')[1].split('</latestReleaseRepositoryId>')[0]+'<br>'
					else
						dt = dt + i+'\t\t\t'+result[i].split('<groupId>')[1].split('</groupId>')[0]+'\t\t'+result[i].split('<artifactId>')[1].split('</artifactId>')[0]+'\t\t'+result[i].split('<version>')[1].split('</version>')[0]+'\t\t'+result[i].split('<latestSnapshotRepositoryId>')[1].split('</latestSnapshotRepositoryId>')[0]+'<br>'
			msg.send dt
			setTimeout (->index.passData dt),1000
