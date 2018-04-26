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
Configuration:

1. XLDEPLOY_URL	
2. XLDEPLOY_USERNAME
3. XLDEPLOY_PASSWORD
4. HUBOT_NAME

Bot commands

1. delete role <rolename> 
2. get role
3. get user <username>
4. create user <username> with password <password>
5. delete user <username>
6. assign role <rolename>  from user <username>
7. delete assignedrole <rolename>  from user <username>
8. get repo

Dependencies:
1. "elasticSearch": "^0.9.2"
2. "request": "2.81.0"

###

eindex = require('./index')
request= require('request')
xldeploy_url = process.env.XLDEPLOY_URL
username = process.env.XLDEPLOY_USERNAME
pawwsord = process.env.XLDEPLOY_PASSWORD
botname = process.env.HUBOT_NAME
deployapi = require('./xldeploy.js')
createrepo = require('./addinfra.js')
updaterepo = require('./updateinfra.js')
deleterepo = require('./deleteinfra.js')
undeploy = require('./undeploy.js')
deleterepo = require('./deleteinfra.js')
createrole = require('./createrole.js')
deleterole = require('./deleterole.js')
getrole = require('./getrole.js')
getuser = require('./getuser.js')
createuser = require('./createuser.js')
deleteuser = require('./deleteuser.js')
assignrole = require('./assignrole.js')
delassignrole = require('./delassignrole.js')
getrepo = require('./getrepo.js')
getjson = require './getjson.js'
generate_id = require('./mongoConnt')

module.exports = (robot) ->

	robot.respond /delete role (.*)/i, (msg) ->
		
		name = msg.match[1]
		
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.deleterole.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					#Prepare payload for slack
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"xldeploy_deleterole","name":name}
					message = {"text": "Request from "+msg.message.user.name+" for deleting role "+name,"attachments": [{"text": "U can Approve or Reject","fallback": "failed to respond","callback_id": "xldeploy_deleterole","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approved","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.deleterole.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.deleterole.admin
					
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert

			#Normal action without workflow flag
			else
				deleterole.deleterole xldeploy_url, username, pawwsord, name, (error, stdout, stderr) ->
					if error
						setTimeout (->eindex.passData error),1000
						console.log(error)
						msg.send "Error occured while deleting role";
					if stderr
						setTimeout (->eindex.passData stderr),1000
						console.log(stderr)
						msg.send stderr;
					if stdout
						setTimeout (->eindex.passData stdout),1000
						message = "xldeploy role deleted"
						actionmsg = "xldeploy role deleted"
						statusmsg = "sucess"
						eindex.wallData botname, message, actionmsg, statusmsg;
						console.log(stdout);
						msg.send stdout;
						
	#Listening the post url
	robot.router.post '/xldeploy_deleterole', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						deleterole.deleterole xldeploy_url, username, pawwsord, data.name, (error, stdout, stderr) ->
							if error
								setTimeout (->eindex.passData error),1000
								console.log(error)
								robot.messageRoom data.userid, "Error occured while deleting role";
							if stderr
								setTimeout (->eindex.passData stderr),1000
								console.log(stderr)
								robot.messageRoom data.userid, stderr;
							if stdout
								setTimeout (->eindex.passData stdout),1000
								message = "xldeploy role deleted"
								actionmsg = "xldeploy role deleted"
								statusmsg = "sucess"
								eindex.wallData botname, message, actionmsg, statusmsg;
								console.log(stdout);
								robot.messageRoom data.userid, stdout;
					#Action flow after reject
					else
						robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
					response.send 'success http call'
					
	robot.respond /get role/i, (msg) ->
		
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.getrole.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					#Prepare payload for slack
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"xldeploy_getrole"}
					message = {"text": "Request from "+msg.message.user.name+" for getting roles ","attachments": [{"text": "U can Approve or Reject","fallback": "failed to respond","callback_id": "xldeploy_getrole","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approved","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.getrole.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.getrole.admin
					
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert

			#Normal action without workflow flag
			else
				getrole.getrole xldeploy_url, username, pawwsord, (error, stdout, stderr) ->
					if error
						setTimeout (->eindex.passData error),1000
						console.log(error)
						msg.send "Error occured while getting role";
					if stderr
						setTimeout (->eindex.passData stderr),1000
						console.log(stderr)
						msg.send stderr;
					if stdout
						setTimeout (->eindex.passData stdout),1000
						console.log(stdout);
						msg.send stdout;
						
	#Listening the post url
	robot.router.post '/xldeploy_getrole', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						getrole.getrole xldeploy_url, username, pawwsord, (error, stdout, stderr) ->
							if error
								setTimeout (->eindex.passData error),1000
								console.log(error)
								robot.messageRoom data.userid, "Error occured while getting role";
							if stderr
								setTimeout (->eindex.passData stderr),1000
								console.log(stderr)
								robot.messageRoom data.userid, stderr;
							if stdout
								setTimeout (->eindex.passData stdout),1000
								console.log(stdout);
								robot.messageRoom data.userid, stdout;
					#Action flow after reject
					else
						robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
					response.send 'success http call'
					
	robot.respond /get user (.*)/i, (msg) ->
		
		name=msg.match[1]
		
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.getuser.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					#Prepare payload for slack
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"xldeploy_getuser","name":name}
					message = {"text": "Request from "+msg.message.user.name+" for gettting user info of "+name,"attachments": [{"text": "U can Approve or Reject","fallback": "failed to respond","callback_id": "xldeploy_getuser","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approved","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.getuser.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.getuser.admin
					
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert

			#Normal action without workflow flag
			else
				getuser.getuser xldeploy_url, username, pawwsord, name, (error, stdout, stderr) ->
					if error
						setTimeout (->eindex.passData error),1000
						console.log(error)
						msg.send "Error occured while getting user";
					if stderr
						setTimeout (->eindex.passData stderr),1000
						console.log(stderr)
						msg.send stderr;
					if stdout
						setTimeout (->eindex.passData stdout),1000
						console.log(stdout);
						msg.send stdout;
						
	#Listening the post url
	robot.router.post '/xldeploy_getuser', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						getuser.getuser xldeploy_url, username, pawwsord, data.name, (error, stdout, stderr) ->
							if error
								setTimeout (->eindex.passData error),1000
								console.log(error)
								robot.messageRoom data.userid, "Error occured while getting user";
							if stderr
								setTimeout (->eindex.passData stderr),1000
								console.log(stderr)
								robot.messageRoom data.userid, stderr;
							if stdout
								setTimeout (->eindex.passData stdout),1000
								console.log(stdout);
								robot.messageRoom data.userid, stdout;
					#Action flow after reject
					else
						robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
					response.send 'success http call'
					
	robot.respond /create user (.*) with password (.*)/i, (msg) ->
		
		name = msg.match[1]
		pwd = msg.match[2]
		
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.createuser.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					#Prepare payload for slack
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"xldeploy_createuser","name":name,"pwd":pwd}
					message = {"text": "Request from "+msg.message.user.name+" for create user "+name,"attachments": [{"text": "U can Approve or Reject","fallback": "failed to respond","callback_id": "xldeploy_createuser","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approved","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.createuser.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.createuser.admin
					
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert

			#Normal action without workflow flag
			else
				createuser.createuser xldeploy_url, username, pawwsord, name, pwd, (error, stdout, stderr) ->
					if error
						setTimeout (->eindex.passData error),1000
						console.log(error)
						msg.send "Error occured while creating user";
					if stderr
						setTimeout (->eindex.passData stderr),1000
						console.log(stderr)
						msg.send stderr;
					if stdout
						setTimeout (->eindex.passData stdout),1000
						message = "xldeploy role deleted"
						actionmsg = "xldeploy role deleted"
						statusmsg = "sucess"
						eindex.wallData botname, message, actionmsg, statusmsg;
						console.log(stdout);
						msg.send stdout;
						
	#Listening the post url
	robot.router.post '/xldeploy_createuser', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						createuser.createuser xldeploy_url, username, pawwsord, data.name, data.pwd, (error, stdout, stderr) ->
							if error
								setTimeout (->eindex.passData error),1000
								console.log(error)
								robot.messageRoom data.userid, "Error occured while creating user";
							if stderr
								setTimeout (->eindex.passData stderr),1000
								console.log(stderr)
								robot.messageRoom data.userid, stderr;
							if stdout
								setTimeout (->eindex.passData stdout),1000
								console.log(stdout);
								robot.messageRoom data.userid, stdout;
					#Action flow after reject
					else
						robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
					response.send 'success http call'
					
	robot.respond /delete user (.*)/i, (msg) ->
		
		name = msg.match[1]
		
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.deleteuser.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					#Prepare payload for slack
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"xldeploy_deleteuser","name":name}
					message = {"text": "Request from "+msg.message.user.name+" for delete user "+name,"attachments": [{"text": "U can Approve or Reject","fallback": "failed to respond","callback_id": "xldeploy_deleteuser","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approved","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.deleteuser.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.deleteuser.admin
					
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert

			#Normal action without workflow flag
			else
				deleteuser.deleteuser xldeploy_url, username, pawwsord, name, (error, stdout, stderr) ->
					if error
						setTimeout (->eindex.passData error),1000
						console.log(error)
						msg.send "Error occured while deleting user";
					if stderr
						setTimeout (->eindex.passData stderr),1000
						console.log(stderr)
						msg.send stderr;
					if stdout
						setTimeout (->eindex.passData stdout),1000
						console.log(stdout);
						msg.send stdout;
						
	#Listening the post url
	robot.router.post '/xldeploy_deleteuser', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						deleteuser.deleteuser xldeploy_url, username, pawwsord, data.name, (error, stdout, stderr) ->
							if error
								setTimeout (->eindex.passData error),1000
								console.log(error)
								robot.messageRoom data.userid, "Error occured while deleting user";
							if stderr
								setTimeout (->eindex.passData stderr),1000
								console.log(stderr)
								robot.messageRoom data.userid, stderr;
							if stdout
								setTimeout (->eindex.passData stdout),1000
								console.log(stdout);
								robot.messageRoom data.userid, stdout;
					#Action flow after reject
					else
						robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
					response.send 'success http call'
					
	robot.respond /assign role (.*) from user (.*)/i, (msg) ->
		
		name = msg.match[2]
		role = msg.match[1]
		
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.assignrole.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					#Prepare payload for slack
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"xldeploy_assignrole","name":name,"role":role}
					message = {"text": "Request from "+msg.message.user.name+" for assign role "+role +' to '+name,"attachments": [{"text": "U can Approve or Reject","fallback": "failed to respond","callback_id": "xldeploy_assignrole","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approved","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.assignrole.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.assignrole.admin
					
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert

			#Normal action without workflow flag
			else
				assignrole.assignrole xldeploy_url, username, pawwsord, name, role, (error, stdout, stderr) ->
					if error
						setTimeout (->eindex.passData error),1000
						console.log(error)
						msg.send "Error occured while assigning role to user";
					if stderr
						setTimeout (->eindex.passData stderr),1000
						console.log(stderr)
						msg.send stderr;
					if stdout
						setTimeout (->eindex.passData stdout),1000
						console.log(stdout);
						msg.send stdout;
						
	#Listening the post url
	robot.router.post '/xldeploy_assignrole', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						assignrole.assignrole xldeploy_url, username, pawwsord, data.name, data.role, (error, stdout, stderr) ->
							if error
								setTimeout (->eindex.passData error),1000
								console.log(error)
								robot.messageRoom data.userid, "Error occured while assigning role to user";
							if stderr
								setTimeout (->eindex.passData stderr),1000
								console.log(stderr)
								robot.messageRoom data.userid, stderr;
							if stdout
								setTimeout (->eindex.passData stdout),1000
								console.log(stdout);
								robot.messageRoom data.userid, stdout;
					#Action flow after reject
					else
						robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
					response.send 'success http call'
					
	robot.respond /delete assignedrole (.*) from user (.*)/i, (msg) ->
		
		name = msg.match[2]
		role = msg.match[1]
		
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.delassignrole.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					#Prepare payload for slack
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"xldeploy_delassignrole","name":name,"role":role}
					message = {"text": "Request from "+msg.message.user.name+" for deleted assign role "+role +' from '+name,"attachments": [{"text": "U can Approve or Reject","fallback": "failed to respond","callback_id": "xldeploy_delassignrole","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approved","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.delassignrole.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.delassignrole.admin
					
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert

			#Normal action without workflow flag
			else
				delassignrole.delassignrole xldeploy_url, username, pawwsord, name, role, (error, stdout, stderr) ->
					if error
						setTimeout (->eindex.passData error),1000
						console.log(error)
						msg.send "Error occured while deleting assigned role to user";
					if stderr
						setTimeout (->eindex.passData stderr),1000
						console.log(stderr)
						msg.send stderr;
					if stdout
						setTimeout (->eindex.passData stdout),1000
						console.log(stdout);
						msg.send stdout;
						
	#Listening the post url
	robot.router.post '/xldeploy_delassignrole', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						delassignrole.delassignrole xldeploy_url, username, pawwsord, data.name, data.role, (error, stdout, stderr) ->
							if error
								setTimeout (->eindex.passData error),1000
								console.log(error)
								robot.messageRoom data.userid, "Error occured while deleting assigned role to user";
							if stderr
								setTimeout (->eindex.passData stderr),1000
								console.log(stderr)
								robot.messageRoom data.userid, stderr;
							if stdout
								setTimeout (->eindex.passData stdout),1000
								console.log(stdout);
								robot.messageRoom data.userid, stdout;
					#Action flow after reject
					else
						robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
					response.send 'success http call'
					
	robot.respond /get repo/i, (msg) ->
		
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.getrepo.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					#Prepare payload for slack
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"xldeploy_getrepo"}
					message = {"text": "Request from "+msg.message.user.name+" for get repo ","attachments": [{"text": "U can Approve or Reject","fallback": "failed to respond","callback_id": "xldeploy_getrepo","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approved","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.getrepo.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.getrepo.admin
					
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert

			#Normal action without workflow flag
			else
				getrepo.getrepo xldeploy_url, username, pawwsord, (error, stdout, stderr) ->
					if error
						setTimeout (->eindex.passData error),1000
						console.log(error)
						msg.send "Error occured while getting repo";
					if stderr
						setTimeout (->eindex.passData stderr),1000
						console.log(stderr)
						msg.send stderr;
					if stdout
						setTimeout (->eindex.passData stdout),1000
						console.log(stdout);
						msg.send stdout;
						
	#Listening the post url
	robot.router.post '/xldeploy_getrepo', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						getrepo.getrepo xldeploy_url, username, pawwsord, (error, stdout, stderr) ->
							if error
								setTimeout (->eindex.passData error),1000
								console.log(error)
								robot.messageRoom data.userid, "Error occured while getting repo";
							if stderr
								setTimeout (->eindex.passData stderr),1000
								console.log(stderr)
								robot.messageRoom data.userid, stderr;
							if stdout
								setTimeout (->eindex.passData stdout),1000
								console.log(stdout);
								robot.messageRoom data.userid, stdout;
					#Action flow after reject
					else
						robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
					response.send 'success http call'
