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
	cmddeleterole = new RegExp('@' +process.env.HUBOT_NAME+' delete role (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddeleterole
		(msg) ->
			name = msg.match[1]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.deleterole.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Prepare payload for mattermost
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.deleterole.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,name:name,callback_id: 'xldeploy_deleterole',tckid:tckid};
						data = {"channel": stdout.deleterole.admin,"text":"Request from "+payload.username+" for delete role in XL-deploy components","message":"Approve Request for delete role in XL-deploy components",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'xldeploy_deleterole',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.deleterole.admin);
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
	)
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
	
	cmdgetrole = new RegExp('@' +process.env.HUBOT_NAME+' get role')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdgetrole
		(msg) ->
			getjson.getworkflow_coffee (error,stdout,stderr) ->
				#Action Flow with workflow flag
				if(stdout.getrole.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Prepare payload for mattermost
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.getrole.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'xldeploy_getrole',tckid:tckid};
						data = {"channel": stdout.getrole.admin,"text":"Request from "+payload.username+" for get role in XL-deploy components","message":"Approve Request for get role in XL-deploy components",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'xldeploy_getrole',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.getrole.admin);
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
	)
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
					
	cmdgetuser = new RegExp('@' +process.env.HUBOT_NAME+' get user (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdgetuser
		(msg) ->
			name=msg.match[1]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
				#Action Flow with workflow flag
				if(stdout.getuser.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Prepare payload for mattermost
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.getuser.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,name:name,callback_id: 'xldeploy_getuser',tckid:tckid};
						data = {"channel": stdout.getuser.admin,"text":"Request from "+payload.username+" for get user in XL-deploy components","message":"Approve Request for get user in XL-deploy components",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'xldeploy_getuser',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.getuser.admin);
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
	)
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
	
	cmdcreateuser = new RegExp('@' +process.env.HUBOT_NAME+' create user (.*) with password (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreateuser
		(msg) ->
			name = msg.match[1]
			pwd = msg.match[2]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.createuser.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Prepare payload for mattermost
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.createuser.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,name:name,pwd:pwd,callback_id: 'xldeploy_createuser',tckid:tckid};
						data = {"channel": stdout.createuser.admin,"text":"Request from "+payload.username+" for create user in XL-deploy components with password","message":"Approve Request for creating user in XL-deploy components",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'xldeploy_createuser',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.createuser.admin);
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
	)
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
	
	cmddeleteuser = new RegExp('@'+process.env.HUBOT_NAME+' delete user (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddeleteuser
		(msg) ->
			name = msg.match[1]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.deleteuser.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Prepare payload for mattermost
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.deleteuser.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,name:name,callback_id: 'xldeploy_deleteuser',tckid:tckid};
						data = {"channel": stdout.deleteuser.admin,"text":"Request from "+payload.username+" for delete user in XL-deploy components","message":"Approve Request for deleting user in XL-deploy components",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'xldeploy_deleteuser',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.deleteuser.admin);
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
	)
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
	cmdassignrole = new RegExp('@'+process.env.HUBOT_NAME+' assign role (.*) from user (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdassignrole
		(msg) ->
			name = msg.match[2]
			role = msg.match[1]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.assignrole.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Prepare payload for mattermost
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.assignrole.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,name:name,role:role,callback_id: 'xldeploy_assignrole',tckid:tckid};
						data = {"channel": stdout.assignrole.admin,"text":"Request from "+payload.username+" for assignrole in XL-deploy components","message":"Approve Request for assign role in XL-deploy components",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'xldeploy_assignrole',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.assignrole.admin);
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
	)
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
	cmddelassignrole = new RegExp('@' +process.env.HUBOT_NAME+' delete assigned role (.*) from user (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddelassignrole
		(msg) ->
			name = msg.match[2]
			role = msg.match[1]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.delassignrole.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Prepare payload for mattermost
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.delassignrole.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,name:name,role:role,callback_id: 'xldeploy_delassignrole',tckid:tckid};
						data = {"channel": stdout.delassignrole.admin,"text":"Request from "+payload.username+" for delete assignrole in XL-deploy components","message":"Approve Request for delete assignrole in XL-deploy components",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'xldeploy_delassignrole',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.delassignrole.admin);
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
	)
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
	cmdgetrepo = new RegExp('@'+process.env.HUBOT_NAME+' get repo')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdgetrepo
		(msg) ->
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.getrepo.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Prepare payload for mattermost
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.getrepo.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'xldeploy_getrepo',tckid:tckid};
						data = {"channel": stdout.getrepo.admin,"text":"Request from "+payload.username+" for get repo in XL-deploy components","message":"Approve Request for get repo in XL-deploy components",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'xldeploy_getrepo',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.getrepo.admin);
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
	)
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
