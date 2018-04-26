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
	robot.respond /assign task (.*) to (.*)/i, (msg) ->
		taskid = msg.match[1]
		username =msg.match[2]
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.assigntask.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					#Prepare payload for slack
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"XLRELEASE_ASSIGNTASK","taskid":taskid,"username":username}
					message = {"text": "Request from "+msg.message.user.name+" for assigning task to "+username,"attachments": [{"text": "U can Approve or Reject","fallback": "failed to respond","callback_id": "XLRELEASE_ASSIGNTASK","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approved","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.assigntask.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.assigntask.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			#Normal action without workflow flag
			else
				taskassign.assigntask xlrelease_url, username, password, taskid, username, (error, stdout, stderr) ->
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
	#Listening the post url  
	robot.router.post '/XLRELEASE_ASSIGNTASK', (request,response) ->
		data= if request.body.payload? then JSON.parse request.body.payload else request.body
		#Action flow after approve
		if data.action=='Approved'
			robot.messageRoom data.userid, 'your request is approved by '+data.approver;
			taskassign.assigntask xlrelease_url, username, password, data.taskid, data.username, (error, stdout, stderr) ->
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
	robot.respond /complete task (.*) with comment (.*)/i, (msg) ->
		taskid = msg.match[1]
		comment =msg.match[2]
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.comlpetetask.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					#Prepare payload for slack
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"XLRELEASE_COMPLETETASK","taskid":taskid,"comment":comment}
					message = {"text": "Request from "+msg.message.user.name+" for completing task "+taskid,"attachments": [{"text": "U can Approve or Reject","fallback": "failed to respond","callback_id": "XLRELEASE_COMPLETETASK","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approved","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.comlpetetask.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.comlpetetask.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
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
					
	robot.respond /start task (.*) with file (.*)/i, (msg) ->
		taskid = msg.match[1]
		filename =msg.match[2]
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.taskstart.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					#Prepare payload for slack
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"XLRELEASE_STARTTASK","filename":filename,"taskid":taskid}
					message = {"text": "Request from "+msg.message.user.name+" for starting task "+taskid,"attachments": [{"text": "U can Approve or Reject","fallback": "failed to respond","callback_id": "XLRELEASE_STARTTASK","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approved","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.taskstart.adminid, message);
					
					msg.send 'Your request is waiting for approval by '+stdout.taskstart.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
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
					
	robot.respond /delete task (.*)/i, (msg) ->
		taskid = msg.match[1]
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.deltask.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					#Prepare payload for slack
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"XLRELEASE_DELTASK","taskid":taskid}
					message = {"text": "Request from "+msg.message.user.name+" for deleting task "+taskid,"attachments": [{"text": "U can Approve or Reject","fallback": "failed to respond","callback_id": "XLRELEASE_DELTASK","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approved","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.deltask.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.deltask.admin
					
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
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
	robot.respond /delete release (.*)/i, (msg) ->
		releaseid = msg.match[1]
		
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.delrelease.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					#Prepare payload for slack
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"XLRELEASE_DELRELEASE","releaseid":releaseid}
					message = {"text": "Request from "+msg.message.user.name+" for deleting release "+releaseid,"attachments": [{"text": "U can Approve or Reject","fallback": "failed to respond","callback_id": "XLRELEASE_DELRELEASE","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approved","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.delrelease.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.delrelease.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
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
	robot.respond /delete template (.*)/i, (msg) ->
		templateid = msg.match[1]
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.deltemplate.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					#Prepare payload for slack
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"XLRELEASE_DELTEMPLATE","templateid":templateid}
					message = {"text": "Request from "+msg.message.user.name+" for deleting template "+templateid,"attachments": [{"text": "U can Approve or Reject","fallback": "failed to respond","callback_id": "XLRELEASE_DELTEMPLATE","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approved","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.deltemplate.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.deltemplate.admin
					
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
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
	robot.respond /get by title (.*)/i, (msg) ->
		name = msg.match[1]
		
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.getbytiltle.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					#Prepare payload for slack
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"XLRELEASE_GETBYTITLE","name":name}
					message = {"text": "Request from "+msg.message.user.name+" for getting detail of "+name,"attachments": [{"text": "U can Approve or Reject","fallback": "failed to respond","callback_id": "XLRELEASE_GETBYTITLE","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approved","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.getbytiltle.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.getbytiltle.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
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
