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

1. XLRELEASE_URL	
2. XLRELEASE_USERNAME
3. XLRELEASE_PASSWORD
4. HUBOT_NAME

Bot commands

1. create release from template <templateid> with file <filename>
2. create phase in template <templateid> with file <filename>
3. create task or in phase <phaseid> with file <filename>
4. start release <releaseid>
5. comment task <taskid> with comment <commenttask>

Dependencies:

1. "elasticSearch": "^0.9.2"
2. "request": "2.81.0"

###
eindex = require('./index')

request= require('request')
xlrelease_url = process.env.XLRELEASE_URL
username = process.env.XLRELEASE_USERNAME
password = process.env.XLRELEASE_PASSWORD
botname = process.env.HUBOT_NAME
createrelease = require('./release.js');
createtask = require('./task.js');
createphase = require('./phase.js')
createtemplate = require('./releaseapi.js')
startrelease = require('./releasestart.js')
taskcomment = require('./taskcomment.js')
taskassign = require('./assigntask.js')
taskcomplete = require('./taskcomplete.js')
starttask = require('./taskstart.js')
deltask = require('./deltask.js')
delrelease = require('./delrelease.js')
deltemplate = require('./deltemplate.js')
getbytiltle = require('./getbytitle.js')
getjson = require './getjson.js'
generate_id = require('./mongoConnt')
module.exports = (robot) ->
	cmdcreaterelease = new RegExp('@' + process.env.HUBOT_NAME + ' create release from template (.*) with file (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreaterelease
		(msg) ->
			filename = msg.match[2]
			templateid = msg.match[1]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.release.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Prepare payload for mattermost
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.release.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,templateid:templateid,filename:filename,callback_id: 'XLRELEASE_RELEASE',tckid:tckid};
						data = {"channel": stdout.release.admin,"text":"Request from "+payload.username+" to create release in xlrelease","message":"Approve Request to create release from template ID: "+payload.templateid+" with file "+payload.filename,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'XLRELEASE_RELEASE',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.release.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Normal action without workflow flag
				else
					createrelease.release xlrelease_url, username, password, filename, templateid, (error, stdout, stderr) ->
						if error
							setTimeout (->eindex.passData error),1000
							console.log(error)
							msg.send "Error occured while creating release";
						if stderr
							setTimeout (->eindex.passData stderr),1000
							console.log(stderr)
							msg.send stderr;
						if stdout
							setTimeout (->eindex.passData stdout),1000
							message = msg.match[0]
							actionmsg = "xlrelease release created"
							statusmsg = "success"
							eindex.wallData botname, message, actionmsg, statusmsg;
							console.log(stdout);
							msg.send stdout;
	)
	#Listening the post url  
	robot.router.post '/XLRELEASE_RELEASE', (request,response) ->
		data= if request.body.payload? then JSON.parse request.body.payload else request.body
		#Action flow after approve
		if data.action=='Approved'
			robot.messageRoom data.userid, 'your request is approved by '+data.approver;
			createrelease.release xlrelease_url, username, password, data.filename, data.templateid, (error, stdout, stderr) ->
				if error
					setTimeout (->eindex.passData error),1000
					console.log(error)
					robot.messageRoom data.userid, "Error occured while creating release";
				if stderr
					setTimeout (->eindex.passData stderr),1000
					console.log(stderr)
					robot.messageRoom data.userid, stderr;
				if stdout
					setTimeout (->eindex.passData stdout),1000
					message = "create release from template "+data.templateid+" with file "+data.filename
					actionmsg = "xlrelease release created"
					statusmsg = "success"
					eindex.wallData botname, message, actionmsg, statusmsg;
					console.log(stdout);
					robot.messageRoom data.userid, stdout;
		#Action flow after reject
		else
			robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
		response.send 'success http call'
	cmdhelp = new RegExp('@' + process.env.HUBOT_NAME + ' help')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdhelp
		(msg) ->
			dt = 'create release from template <id> with file <filename> \n create phase in template <id> with file <filename> \n create task or in phase <id> with file <filename> \n create template with file <filename> \n start release <id> \n comment task <id> with comment <comment> \n assign task <id> to <username> \n complete task <id> with comment <comment> \n start task <id> with file <filename> \n delete task <id> \n delete release <id> \n delete template <id> \n get by title <id>'
			msg.send dt
			setTimeout (->eindex.passData dt),1000
	)
	cmdcreatephase = new RegExp('@' + process.env.HUBOT_NAME + ' create phase from template (.*) with file (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreatephase
		(msg) ->
			filename = msg.match[2]
			templateid = msg.match[1]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.phase.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Prepare payload for mattermost	
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.phase.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,filename:filename,templateid:templateid,callback_id: 'XLRELEASE_PHASE',tckid:tckid};
						data = {"channel": stdout.phase.admin,"text":"Request from "+payload.username+" to create phase in xlrelease","message":"Approve Request to create phase from template "+payload.templateid+" with file "+payload.filename,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'XLRELEASE_PHASE',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.phase.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Normal action without workflow flag
				else
					createphase.phase xlrelease_url, username, password, filename, templateid, (error, stdout, stderr) ->
						if error
							setTimeout (->eindex.passData error),1000
							console.log(error)
							msg.send "Error occured while creating phase";
						if stderr
							setTimeout (->eindex.passData stderr),1000
							console.log(stderr)
							msg.send stderr;
						if stdout
							setTimeout (->eindex.passData stdout),1000
							message = msg.match[0]
							actionmsg = "xlrelease phase created"
							statusmsg = "success"
							eindex.wallData botname, message, actionmsg, statusmsg;
							msg.send stdout;
	)
	#Listening the post url  
	robot.router.post '/XLRELEASE_PHASE', (request,response) ->
		data= if request.body.payload? then JSON.parse request.body.payload else request.body
		#Action flow after approve
		if data.action=='Approved'
			robot.messageRoom data.userid, 'your request is approved by '+data.approver;
			createphase.phase xlrelease_url, username, password, data.filename, data.templateid, (error, stdout, stderr) ->
				if error
					setTimeout (->eindex.passData error),1000
					console.log(error)
					robot.messageRoom data.userid, "Error occured while creating phase";
				if stderr
					setTimeout (->eindex.passData stderr),1000
					console.log(stderr)
					robot.messageRoom data.userid, stderr;
				if stdout
					setTimeout (->eindex.passData stdout),1000
					message = "create phase from template "+data.templateid+" with file "+data.filename
					actionmsg = "xlrelease phase created"
					statusmsg = "success"
					eindex.wallData botname, message, actionmsg, statusmsg;
					console.log(stdout);
					robot.messageRoom data.userid, stdout;
		#Action flow after reject
		else
			robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
		response.send 'success http call'
	cmdcreatetask = new RegExp('@' + process.env.HUBOT_NAME + ' create task or in phase (.*) with file (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreatetask
		(msg) ->
			filename = msg.match[2]
			phaseid = msg.match[1]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.task.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Prepare payload for mattermost	
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.task.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,filename:filename,phaseid:phaseid,callback_id: 'XLRELEASE_TASK',tckid:tckid};
						data = {"channel": stdout.task.admin,"text":"Request from "+payload.username+" to create xlrelease task","message":"Approve Request to create task from phase id:"+payload.phaseid+" with file "+payload.filename,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'XLRELEASE_TASK',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.task.admin);
						
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Normal action without workflow flag
				else
					createtask.task xlrelease_url, username, password, filename, phaseid, (error, stdout, stderr) ->
						if error
							setTimeout (->eindex.passData error),1000
							console.log(error)
							msg.send "Error occured while creating task";
						if stderr
							setTimeout (->eindex.passData stderr),1000
							console.log(stderr)
							msg.send stderr;
						if stdout
							setTimeout (->eindex.passData stdout),1000
							message = msg.match[0]
							actionmsg = "xlrelease task created"
							statusmsg = "success"
							eindex.wallData botname, message, actionmsg, statusmsg;
							console.log(stdout);
							msg.send stdout;
	)
	#Listening the post url  
	robot.router.post '/XLRELEASE_TASK', (request,response) ->
		data= if request.body.payload? then JSON.parse request.body.payload else request.body
		#Action flow after approve
		if data.action=='Approved'
			robot.messageRoom data.userid, 'your request is approved by '+data.approver;
			createtask.task xlrelease_url, username, password, data.filename, data.phaseid, (error, stdout, stderr) ->
				if error
					setTimeout (->eindex.passData error),1000
					console.log(error)
					robot.messageRoom data.userid, "Error occured while creating task";
				if stderr
					setTimeout (->eindex.passData stderr),1000
					console.log(stderr)
					robot.messageRoom data.userid, stderr;
				if stdout
					setTimeout (->eindex.passData stdout),1000
					message = "create task or in phase "+data.phaseid+" with file "+data.filename
					actionmsg = "xlrelease task created"
					statusmsg = "success"
					eindex.wallData botname, message, actionmsg, statusmsg;
					console.log(stdout);
					robot.messageRoom data.userid, stdout;
		#Action flow after reject
		else
			robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
		response.send 'success http call'
	cmdcreatetemplate = new RegExp('@' + process.env.HUBOT_NAME + ' create template with file (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreatetemplate
		(msg) ->
			filename = msg.match[1]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.template.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Prepare payload for mattermost	
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.template.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,filename:filename,callback_id: 'XLRELEASE_TEMPLATE',tckid:tckid};
						data = {"channel": stdout.template.admin,"text":"Request from "+payload.username+" create template in xlrelease","message":"Approve Request to create template with file "+payload.filename,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'XLRELEASE_TEMPLATE',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.template.admin);
						
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Normal action without workflow flag
				else
					createtemplate.template xlrelease_url, username, password, filename, (error, stdout, stderr) ->
						if error
							setTimeout (->eindex.passData error),1000
							console.log(error)
							msg.send "Error occured while creating template";
						if stderr
							setTimeout (->eindex.passData stderr),1000
							console.log(stderr)
							msg.send stderr;
						if stdout
							setTimeout (->eindex.passData stdout),1000
							message = msg.match[0]
							actionmsg = "xlrelease template created"
							statusmsg = "success"
							eindex.wallData botname, message, actionmsg, statusmsg;
							console.log(stdout);
							msg.send stdout;
	)
	#Listening the post url
	robot.router.post '/XLRELEASE_TEMPLATE', (request,response) ->
		data= if request.body.payload? then JSON.parse request.body.payload else request.body
		#Action flow after approve
		if data.action=='Approved'
			robot.messageRoom data.userid, 'your request is approved by '+data.approver;
			createtemplate.template xlrelease_url, username, password, data.filename, (error, stdout, stderr) ->
				if error
					setTimeout (->eindex.passData error),1000
					console.log(error)
					robot.messageRoom data.userid, "Error occured while creating template";
				if stderr
					setTimeout (->eindex.passData stderr),1000
					console.log(stderr)
					robot.messageRoom data.userid, stderr;
				if stdout
					setTimeout (->eindex.passData stdout),1000
					message = "create template with file "+data.filename
					actionmsg = "xlrelease template created"
					statusmsg = "success"
					eindex.wallData botname, message, actionmsg, statusmsg;
					console.log(stdout);
					robot.messageRoom data.userid, stdout;
		#Action flow after reject
		else
			robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
		response.send 'success http call'
	cmdstartrelease = new RegExp('@' + process.env.HUBOT_NAME + ' start release (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdstartrelease
		(msg) ->
			releaseid = msg.match[1]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.release.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Prepare payload for mattermost	
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.release.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,releaseid:releaseid,callback_id: 'XLRELEASE_START',tckid:tckid};
						data = {"channel": stdout.release.admin,"text":"Request from "+payload.username+" to start release in xlrelease","message":"Approve Request to start release ID: "+payload.releaseid,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'XLRELEASE_START',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.release.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Normal action without workflow flag
				else
					startrelease.releasestart xlrelease_url, username, password, releaseid, (error, stdout, stderr) ->
						if error
							setTimeout (->eindex.passData error),1000
							console.log(error)
							msg.send "Error occured while starting release";
						if stderr
							setTimeout (->eindex.passData stderr),1000
							console.log(stderr)
							msg.send stderr;
						if stdout
							setTimeout (->eindex.passData stdout),1000
							message = msg.match[0]
							actionmsg = "xlrelease release started"
							statusmsg = "success"
							eindex.wallData botname, message, actionmsg, statusmsg;
							console.log(stdout);
							msg.send stdout;
	)
	#Listening the post url  
	robot.router.post '/XLRELEASE_START', (request,response) ->
		data= if request.body.payload? then JSON.parse request.body.payload else request.body
		#Action flow after approve
		if data.action=='Approved'
			robot.messageRoom data.userid, 'your request is approved by '+data.approver;
			startrelease.releasestart xlrelease_url, username, password, data.releaseid, (error, stdout, stderr) ->
				if error
					setTimeout (->eindex.passData error),1000
					console.log(error)
					robot.messageRoom data.userid, "Error occured while starting release";
				if stderr
					setTimeout (->eindex.passData stderr),1000
					console.log(stderr)
					robot.messageRoom data.userid, stderr;
				if stdout
					setTimeout (->eindex.passData stdout),1000
					message = "start release "+data.releaseid
					actionmsg = "xlrelease release started"
					statusmsg = "success"
					eindex.wallData botname, message, actionmsg, statusmsg;
					console.log(stdout);
					robot.messageRoom data.userid, stdout;
		#Action flow after reject
		else
			robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
		response.send 'success http call'
	cmdcommenttask = new RegExp('@' + process.env.HUBOT_NAME + ' comment task (.*) with comment (.+)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcommenttask
		(msg) ->
			taskid = msg.match[1]
			comment =msg.match[2]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.commenttask.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Prepare payload for mattermost	
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.commenttask.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,taskid:taskid,comment:comment,callback_id: 'XLRELEASE_COMMENT',tckid:tckid};
						data = {"channel": stdout.commenttask.admin,"text":"Request from "+payload.username+" add comment to xlrelease task","message":"Approve Request to add comment: *"+payload.comment+"* to task id: "+payload.taskid,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'XLRELEASE_COMMENT',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.commenttask.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Normal action without workflow flag
				else
					taskcomment.taskcomment xlrelease_url, username, password, taskid, comment, (error, stdout, stderr) ->
						if error
							setTimeout (->eindex.passData error),1000
							console.log(error)
							msg.send "Error occured while adding comment";
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
	robot.router.post '/XLRELEASE_COMMENT', (request,response) ->
		data= if request.body.payload? then JSON.parse request.body.payload else request.body
		#Action flow after approve
		if data.action=='Approved'
			robot.messageRoom data.userid, 'your request is approved by '+data.approver;
			taskcomment.taskcomment xlrelease_url, username, password, data.taskid, data.comment, (error, stdout, stderr) ->
				if error
					setTimeout (->eindex.passData error),1000
					console.log(error)
					robot.messageRoom data.userid, "Error occured while adding comment";
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
