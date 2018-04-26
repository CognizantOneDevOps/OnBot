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

1. assign task <taskid> to <username>
2. complete task <taskid> with comment <commenttask>
3. start task <taskid> with file <filename>
4. delete task <taskid>
5. delete release <releaseid>
6. delete template <templateid>
7. get by title <name>

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

	cmdassigntask = new RegExp('@' + process.env.HUBOT_NAME + ' assign task (.*) to (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdassigntask
		(msg) ->
			taskid = msg.match[1]
			name =msg.match[2]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.assigntask.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Prepare payload for mattermost
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.assigntask.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,taskid:taskid,name:name,callback_id: 'XLRELEASE_ASSIGNTASK',tckid:tckid};
						data = {"channel": stdout.assigntask.admin,"text":"Request from "+payload.username+" to assign xlrelease task to user","message":"Approve Request to assign task ID:"+payload.taskid+" to user: "+payload.name,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'XLRELEASE_ASSIGNTASK',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.assigntask.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Normal action without workflow flag
				else
					taskassign.assigntask xlrelease_url, username, password, taskid, name, (error, stdout, stderr) ->
						if error
							setTimeout (->eindex.passData error),1000
							console.log(error)
							msg.send "Error occured while assigning task";
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
	robot.router.post '/XLRELEASE_ASSIGNTASK', (request,response) ->
		data= if request.body.payload? then JSON.parse request.body.payload else request.body
		#Action flow after approve
		if data.action=='Approved'
			robot.messageRoom data.userid, 'your request is approved by '+data.approver;
			taskassign.assigntask xlrelease_url, username, password, data.taskid, data.name, (error, stdout, stderr) ->
				if error
					setTimeout (->eindex.passData error),1000
					console.log(error)
					robot.messageRoom data.userid, "Error occured while assigning task";
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
	cmdcompletetask = new RegExp('@' + process.env.HUBOT_NAME + ' complete task (.*) with comment (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcompletetask
		(msg) ->
			taskid = msg.match[1]
			comment =msg.match[2]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.comlpetetask.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Prepare payload for mattermost
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.comlpetetask.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,taskid:taskid,comment:comment,callback_id: 'XLRELEASE_COMPLETETASK',tckid:tckid};
						data = {"channel": stdout.comlpetetask.admin,"text":"Request from "+payload.username+" to complete xlrelease task with comment","message":"Approve Request complete task ID:"+payload.taskid+" with comment: *"+payload.comment,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'XLRELEASE_COMPLETETASK',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.comlpetetask.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Normal action without workflow flag
				else
					taskcomplete.taskcomplete xlrelease_url, username, password, taskid, comment, (error, stdout, stderr) ->
						if error
							setTimeout (->eindex.passData error),1000
							console.log(error)
							msg.send "Error occured while completing task";
						if stderr
							setTimeout (->eindex.passData stderr),1000
							console.log(stderr)
							msg.send stderr;
						if stdout
							setTimeout (->eindex.passData stdout),1000
							message = msg.match[0]
							actionmsg = "xlrelease task completed"
							statusmsg = "success"
							eindex.wallData botname, message, actionmsg, statusmsg;
							console.log(stdout);
							msg.send stdout;
	)
	#Listening the post url  
	robot.router.post '/XLRELEASE_COMPLETETASK', (request,response) ->
		data= if request.body.payload? then JSON.parse request.body.payload else request.body
		#Action flow after approve
		if data.action=='Approved'
			robot.messageRoom data.userid, 'your request is approved by '+data.approver;
			taskcomplete.taskcomplete xlrelease_url, username, password, data.taskid, data.comment, (error, stdout, stderr) ->
				if error
					setTimeout (->eindex.passData error),1000
					console.log(error)
					robot.messageRoom data.userid, "Error occured while completing task";
				if stderr
					setTimeout (->eindex.passData stderr),1000
					console.log(stderr)
					robot.messageRoom data.userid, stderr;
				if stdout
					setTimeout (->eindex.passData stdout),1000
					message = "complete task "+data.taskid+" with comment "+data.comment
					actionmsg = "xlrelease task completed"
					statusmsg = "success"
					eindex.wallData botname, message, actionmsg, statusmsg;
					console.log(stdout);
					robot.messageRoom data.userid, stdout;
		#Action flow after reject
		else
			robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
		response.send 'success http call'
	cmdstarttask = new RegExp('@' + process.env.HUBOT_NAME + ' start task (.*) with file (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdstarttask
		(msg) ->
			taskid = msg.match[1]
			filename =msg.match[2]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.taskstart.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Prepare payload for mattermost	
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.taskstart.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,filename:filename,taskid:taskid,callback_id: 'XLRELEASE_STARTTASK',tckid:tckid};
						data = {"channel": stdout.taskstart.admin,"text":"Request from "+payload.username+" to start xlrelease task","message":"Approve Request to start task ID: "+payload.taskid+" with file "+payload.filename,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'XLRELEASE_STARTTASK',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.taskstart.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Normal action without workflow flag
				else
					starttask.taskstart xlrelease_url, username, password, filename, taskid, (error, stdout, stderr) ->
						if error
							setTimeout (->eindex.passData error),1000
							console.log(error)
							msg.send "Error occured while stating task";
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
	robot.router.post '/XLRELEASE_STARTTASK', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						starttask.taskstart xlrelease_url, username, password, data.filename, data.taskid, (error, stdout, stderr) ->
							if error
								setTimeout (->eindex.passData error),1000
								console.log(error)
								robot.messageRoom data.userid, "Error occured while stating task";
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
	cmddeletetask = new RegExp('@' + process.env.HUBOT_NAME + ' delete task (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddeletetask
		(msg) ->
			taskid = msg.match[1]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.deltask.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#console.log(tckid);
						#Prepare payload for mattermost		
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.deltask.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,taskid:taskid,callback_id: 'XLRELEASE_DELTASK',tckid:tckid};
						data = {"channel": stdout.deltask.admin,"text":"Request from "+payload.username+" to delete xlrelease task","message":"Approve Request to delete task ID: "+payload.taskid,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'XLRELEASE_DELTASK',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.deltask.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Normal action without workflow flag
				else
					deltask.taskdel xlrelease_url, username, password, taskid, (error, stdout, stderr) ->
						if error
							setTimeout (->eindex.passData error),1000
							console.log(error)
							msg.send "Error occured while deleting task";
						if stderr
							setTimeout (->eindex.passData stderr),1000
							console.log(stderr)
							msg.send stderr;
						if stdout
							setTimeout (->eindex.passData stdout),1000
							message = msg.match[0]
							actionmsg = "xlrelease task deleted"
							statusmsg = "success"
							eindex.wallData botname, message, actionmsg, statusmsg;
							console.log(stdout);
							msg.send stdout;
	)
	#Listening the post url  
	robot.router.post '/XLRELEASE_DELTASK', (request,response) ->
		data= if request.body.payload? then JSON.parse request.body.payload else request.body
		#Action flow after approve
		if data.action=='Approved'
			robot.messageRoom data.userid, 'your request is approved by '+data.approver;
			deltask.taskdel xlrelease_url, username, password, data.taskid, (error, stdout, stderr) ->
				if error
					setTimeout (->eindex.passData error),1000
					console.log(error)
					robot.messageRoom data.userid, "Error occured while deleting task";
				if stderr
					setTimeout (->eindex.passData stderr),1000
					console.log(stderr)
					robot.messageRoom data.userid, stderr;
				if stdout
					setTimeout (->eindex.passData stdout),1000
					message = "delete task "+data.taskid
					actionmsg = "xlrelease task deleted"
					statusmsg = "success"
					eindex.wallData botname, message, actionmsg, statusmsg;
					console.log(stdout);
					robot.messageRoom data.userid, stdout;
		#Action flow after reject
		else
			robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
		response.send 'success http call'
	cmddeleterelease = new RegExp('@' + process.env.HUBOT_NAME + ' delete release (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddeleterelease
		(msg) ->
			releaseid = msg.match[1]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.delrelease.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Prepare payload for mattermost	
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.delrelease.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,releaseid:releaseid,callback_id: 'XLRELEASE_DELRELEASE',tckid:tckid};
						data = {"channel": stdout.delrelease.admin,"text":"Request from "+payload.username+" to delete release in xlrelease","message":"Approve Request to delete release ID:"+payload.releaseid,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'XLRELEASE_DELRELEASE',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.delrelease.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Normal action without workflow flag
				else
					delrelease.releasedel xlrelease_url, username, password, releaseid, (error, stdout, stderr) ->
						if error
							setTimeout (->eindex.passData error),1000
							console.log(error)
							msg.send "Error occured while deleting release";
						if stderr
							setTimeout (->eindex.passData stderr),1000
							console.log(stderr)
							msg.send stderr;
						if stdout
							setTimeout (->eindex.passData stdout),1000
							message = msg.match[0]
							actionmsg = "xlrelease release deleted"
							statusmsg = "success"
							eindex.wallData botname, message, actionmsg, statusmsg;
							console.log(stdout);
							msg.send stdout;
	)
	#Listening the post url  
	robot.router.post '/XLRELEASE_DELRELEASE', (request,response) ->
		data= if request.body.payload? then JSON.parse request.body.payload else request.body
		#Action flow after approve
		if data.action=='Approved'
			robot.messageRoom data.userid, 'your request is approved by '+data.approver;
			delrelease.releasedel xlrelease_url, username, password, data.releaseid, (error, stdout, stderr) ->
				if error
					setTimeout (->eindex.passData error),1000
					console.log(error)
					robot.messageRoom data.userid, "Error occured while deleting release";
				if stderr
					setTimeout (->eindex.passData stderr),1000
					console.log(stderr)
					robot.messageRoom data.userid, stderr;
				if stdout
					setTimeout (->eindex.passData stdout),1000
					message = "delete release "+data.releaseid
					actionmsg = "xlrelease release deleted"
					statusmsg = "success"
					eindex.wallData botname, message, actionmsg, statusmsg;
					console.log(stdout);
					robot.messageRoom data.userid, stdout;
		#Action flow after reject
		else
			robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
		response.send 'success http call'
	cmddeletetemplate = new RegExp('@' + process.env.HUBOT_NAME + ' delete template (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddeletetemplate
		(msg) ->
			templateid = msg.match[1]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.deltemplate.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Prepare payload for mattermost
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.deltemplate.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,templateid:templateid,callback_id: 'XLRELEASE_DELTEMPLATE',tckid:tckid};
						data = {"channel": stdout.deltemplate.admin,"text":"Request from "+payload.username+" to delete xlrelease template","message":"Approve Request to delete template ID:"+payload.templateid,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'XLRELEASE_DELTEMPLATE',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.deltemplate.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Normal action without workflow flag
				else
					deltemplate.templatedel xlrelease_url, username, password, templateid, (error, stdout, stderr) ->
						if error
							setTimeout (->eindex.passData error),1000
							console.log(error)
							msg.send "Error occured while deleting template";
						if stderr
							setTimeout (->eindex.passData stderr),1000
							console.log(stderr)
							msg.send stderr;
						if stdout
							setTimeout (->eindex.passData stdout),1000
							message = msg.match[0]
							actionmsg = "xlrelease template deleted"
							statusmsg = "success"
							eindex.wallData botname, message, actionmsg, statusmsg;
							console.log(stdout);
							msg.send stdout;
	)
	#Listening the post url  
	robot.router.post '/XLRELEASE_DELTEMPLATE', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						deltemplate.templatedel xlrelease_url, username, password, data.templateid, (error, stdout, stderr) ->
							if error
								setTimeout (->eindex.passData error),1000
								console.log(error)
								robot.messageRoom data.userid, "Error occured while deleting template";
							if stderr
								setTimeout (->eindex.passData stderr),1000
								console.log(stderr)
								robot.messageRoom data.userid, stderr;
							if stdout
								setTimeout (->eindex.passData stdout),1000
								message = "delete template "+data.templateid
								actionmsg = "xlrelease template deleted"
								statusmsg = "success"
								eindex.wallData botname, message, actionmsg, statusmsg;
								console.log(stdout);
								robot.messageRoom data.userid, stdout;
					#Action flow after reject
					else
						robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
					response.send 'success http call'
	cmdgettytitle = new RegExp('@' + process.env.HUBOT_NAME + ' get by title (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdgettytitle
		(msg) ->
			name = msg.match[1]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.getbytiltle.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Prepare payload for mattermost		
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.getbytiltle.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,name:name,callback_id: 'XLRELEASE_GETBYTITLE',tckid:tckid};
						data = {"channel": stdout.getbytiltle.admin,"text":"Request from "+payload.username+" to get xlrelease info by release title","message":"Approve Request to get info by title: "+payload.name,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'XLRELEASE_GETBYTITLE',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.getbytiltle.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Normal action without workflow flag
				else
					getbytiltle.titleget xlrelease_url, username, password, name, (error, stdout, stderr) ->
						if error
							setTimeout (->eindex.passData error),1000
							console.log(error)
							msg.send "Error occured while getting info";
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
	robot.router.post '/XLRELEASE_GETBYTITLE', (request,response) ->
		data= if request.body.payload? then JSON.parse request.body.payload else request.body
		#Action flow after approve
		if data.action=='Approved'
			robot.messageRoom data.userid, 'your request is approved by '+data.approver;
			getbytiltle.titleget xlrelease_url, username, password, data.name, (error, stdout, stderr) ->
				if error
					setTimeout (->eindex.passData error),1000
					console.log(error)
					robot.messageRoom data.userid, "Error occured while getting info";
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
