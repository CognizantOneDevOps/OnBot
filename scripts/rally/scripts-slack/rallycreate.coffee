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

#Description:
# This script listens to all the creation commands handled by CARally bot,
# passes them to the appropriate js files for execution,
# Returns the result of execution back to user
#
#Configuration:
# HUBOT_NAME
# API
# USERNAME
# PASSWORD
#
#Dependencies:
# "request": "2.81.0"

request = require('request')

eindex = require('./index')
readjson = require './readjson.js'

generate_id = require('./mongoConnt')
createbug = require('./createbug.js')
createfeature = require('./createfeature.js')
createepic = require('./createepic.js')
createiteration = require('./createiteration.js')
createrelease = require('./createrelease.js')
createtask = require('./createtask.js')
createtestcase = require('./createtestcase.js')
createuserstory = require('./createuserstory.js')
createproject = require('./createproject.js')

module.exports = (robot) ->
	robot.respond /create Bug (.*) Desc (.*) Priority (.*) Severity (.*) and Status (.*)/, (res) ->
		name=res.match[1]
		desc=res.match[2]
		priority=res.match[3]
		severity=res.match[4]
		status=res.match[5]
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
			if stdout.createbug.workflowflag == true
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"createbug",name:name,desc:desc,priority:priority,severity:severity,status:status}
					message = {"text": "Request from "+payload.username+" to create bug "+name,"attachments": [{"text": "You can Approve or Reject","fallback": "failed to respond","callback_id": "createbug","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approve","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.createbug.adminid, message);
					res.send 'Your request is waiting for approval by '+stdout.createbug.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			#Casual workflow
			else
				createbug.createbug process.env.API, process.env.USERNAME, process.env.PASSWORD, name, desc, priority, severity, status, (error,stdout,stderr) ->
					if(stdout)
						console.log(stdout)
						res.send stdout 
						setTimeout (->eindex.passData stdout),1000
						
					if(stderr)
						console.log(stderr)
						res.send stderr
						setTimeout (->eindex.passData stderr),1000
					
					if(error)
						console.log(error)
						res.send error
						setTimeout (->eindex.passData error),1000
					
	robot.router.post '/createbug', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' for the creating bug';
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			name = request.body.name;
			desc = request.body.desc;
			priority = request.body.priority;
			severity = request.body.severity;
			status = request.body.status;
			# Call from create_project file for project creation 
			createbug.createbug process.env.API, process.env.USERNAME, process.env.PASSWORD, name, desc, priority, severity, status, (error,stdout,stderr) ->
				if(stdout)
					console.log(stdout)
					robot.messageRoom data_http.userid, stdout; 
					setTimeout (->eindex.passData stdout),1000
					
				if(stderr)
					console.log(stderr)
					robot.messageRoom data_http.userid, stderr;
					setTimeout (->eindex.passData stderr),1000
				
				if(error)
					console.log(error)
					robot.messageRoom data_http.userid, error;
					setTimeout (->eindex.passData error),1000
		else
			dt="creating bug request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to creating bug.';

	robot.respond /create Feature (.*) Desc (.*) and Status (.*)/, (res) ->
		name=res.match[1]
		desc=res.match[2]
		status=res.match[3]
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
			if stdout.createfeature.workflowflag == true
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"createfeature",name:name,desc:desc,status:status}
					message = {"text": "Request from "+payload.username+" to create feature "+name,"attachments": [{"text": "You can Approve or Reject","fallback": "failed to respond","callback_id": "createfeature","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approve","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.createfeature.adminid, message);
					res.send 'Your request is waiting for approval by '+stdout.createfeature.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			#Casual workflow
			else
				createfeature.createfeature process.env.API, process.env.USERNAME, process.env.PASSWORD, name, desc, status, (error,stdout,stderr) ->
					if(stdout)
						console.log(stdout)
						res.send stdout 
						setTimeout (->eindex.passData stdout),1000
						
					if(stderr)
						console.log(stderr)
						res.send stderr
						setTimeout (->eindex.passData stderr),1000
					
					if(error)
						console.log(error)
						res.send error
						setTimeout (->eindex.passData error),1000
					
	robot.router.post '/createfeature', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' for the creating feature';
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			name = request.body.name;
			desc = request.body.desc;
			status = request.body.status;
			# Call from create_project file for project creation 
			createfeature.createfeature process.env.API, process.env.USERNAME, process.env.PASSWORD, name, desc, status, (error,stdout,stderr) ->
				if(stdout)
					console.log(stdout)
					robot.messageRoom data_http.userid, stdout; 
					setTimeout (->eindex.passData stdout),1000
				if(stderr)
					console.log(stderr)
					robot.messageRoom data_http.userid, stderr;
					setTimeout (->eindex.passData stderr),1000
				
				if(error)
					console.log(error)
					robot.messageRoom data_http.userid, error;
					setTimeout (->eindex.passData error),1000
		else
			dt="creating feature request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to creating feature.';
			
	robot.respond /create Epic (.*) Desc (.*) and Status (.*)/, (res) ->
		name=res.match[1]
		desc=res.match[2]
		status=res.match[3]
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
			if stdout.createepic.workflowflag == true
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"createepic",name:name,desc:desc,status:status}
					message = {"text": "Request from "+payload.username+" to create epic "+name,"attachments": [{"text": "You can Approve or Reject","fallback": "failed to respond","callback_id": "createepic","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approve","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.createepic.adminid, message);
					res.send 'Your request is waiting for approval by '+stdout.createepic.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			#Casual workflow
			else
				createepic.createepic process.env.API, process.env.USERNAME, process.env.PASSWORD, name, desc, status, (error,stdout,stderr) ->
					if(stdout)
						console.log(stdout)
						res.send stdout 
						setTimeout (->eindex.passData stdout),1000
						
					if(stderr)
						console.log(stderr)
						res.send stderr
						setTimeout (->eindex.passData stderr),1000
					
					if(error)
						console.log(error)
						res.send error
						setTimeout (->eindex.passData error),1000
						
	robot.router.post '/createepic', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' for the creating epic';
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			name = request.body.name;
			desc = request.body.desc;
			status = request.body.status;
			# Call from create_project file for project creation 
			createepic.createepic process.env.API, process.env.USERNAME, process.env.PASSWORD, name, desc, status, (error,stdout,stderr) ->
				if(stdout)
					console.log(stdout)
					robot.messageRoom data_http.userid, stdout; 
					setTimeout (->eindex.passData stdout),1000
					
				if(stderr)
					console.log(stderr)
					robot.messageRoom data_http.userid, stderr;
					setTimeout (->eindex.passData stderr),1000
				
				if(error)
					console.log(error)
					robot.messageRoom data_http.userid, error;
					setTimeout (->eindex.passData error),1000
		else
			dt="creating epic request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to creating epic.';
			
	robot.respond /create iteration (.*) startdate (.*) Enddate (.*) and Status (.*)/, (res) ->
		name=res.match[1]
		startdate=res.match[2]
		enddate=res.match[3]
		status=res.match[4]
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
			if stdout.createiteration.workflowflag == true
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"createiteration",name:name,startdate:startdate,enddate:enddate,status:status}
					message = {"text": "Request from "+payload.username+" to create iteration "+name,"attachments": [{"text": "You can Approve or Reject","fallback": "failed to respond","callback_id": "createiteration","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approve","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.createiteration.adminid, message);
					res.send 'Your request is waiting for approval by '+stdout.createiteration.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			#Casual workflow
			else
				createiteration.createiteration process.env.API, process.env.USERNAME, process.env.PASSWORD, name, startdate, enddate, status, (error,stdout,stderr) ->
					if(stdout)
						console.log(stdout)
						res.send stdout 
						setTimeout (->eindex.passData stdout),1000
						
					if(stderr)
						console.log(stderr)
						res.send stderr
						setTimeout (->eindex.passData stderr),1000
					
					if(error)
						console.log(error)
						res.send error
						setTimeout (->eindex.passData error),1000
						
	robot.router.post '/createiteration', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' for the creating iteration';
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			name = request.body.name;
			enddate = request.body.enddate;
			startdate = request.body.startdate;
			status = request.body.status;
			# Call from create_project file for project creation 
			createiteration.createiteration process.env.API, process.env.USERNAME, process.env.PASSWORD, name, startdate, enddate, status, (error,stdout,stderr) ->
				if(stdout)
					console.log(stdout)
					robot.messageRoom data_http.userid, stdout; 
					setTimeout (->eindex.passData stdout),1000
					
				if(stderr)
					console.log(stderr)
					robot.messageRoom data_http.userid, stderr;
					setTimeout (->eindex.passData stderr),1000
				
				if(error)
					console.log(error)
					robot.messageRoom data_http.userid, error;
					setTimeout (->eindex.passData error),1000
		else
			dt="creating iteration request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to creating iteration.';
			
	robot.respond /create release (.*) startdate (.*) Enddate (.*) and Status (.*)/, (res) ->
		name=res.match[1]
		startdate=res.match[2]
		enddate=res.match[3]
		status=res.match[4]
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
			if stdout.createrelease.workflowflag == true
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"createrelease",name:name,startdate:startdate,enddate:enddate,status:status}
					message = {"text": "Request from "+payload.username+" to create release "+name,"attachments": [{"text": "You can Approve or Reject","fallback": "failed to respond","callback_id": "createrelease","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approve","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.createrelease.adminid, message);
					res.send 'Your request is waiting for approval by '+stdout.createrelease.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			#Casual workflow
			else
				createrelease.createrelease process.env.API, process.env.USERNAME, process.env.PASSWORD, name, startdate, enddate, status, (error,stdout,stderr) ->
					if(stdout)
						console.log(stdout)
						res.send stdout 
						setTimeout (->eindex.passData stdout),1000
						
					if(stderr)
						console.log(stderr)
						res.send stderr
						setTimeout (->eindex.passData stderr),1000
					
					if(error)
						console.log(error)
						res.send error
						setTimeout (->eindex.passData error),1000
						
	robot.router.post '/createrelease', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' for the creating release';
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			name = request.body.name;
			enddate = request.body.enddate;
			startdate = request.body.startdate;
			status = request.body.status;
			# Call from create_project file for project creation 
			createrelease.createrelease process.env.API, process.env.USERNAME, process.env.PASSWORD, name, startdate, enddate, status, (error,stdout,stderr) ->
				if(stdout)
					console.log(stdout)
					robot.messageRoom data_http.userid, stdout; 
					setTimeout (->eindex.passData stdout),1000
					
				if(stderr)
					console.log(stderr)
					robot.messageRoom data_http.userid, stderr;
					setTimeout (->eindex.passData stderr),1000
				
				if(error)
					console.log(error)
					robot.messageRoom data_http.userid, error;
					setTimeout (->eindex.passData error),1000
		else
			dt="creating release request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to creating release.';
			
	robot.respond /create task (.*) workproduct (.*)/, (res) ->
		name=res.match[1]
		workproduct=res.match[2]
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
			if stdout.createtask.workflowflag == true
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"createtask",name:name,workproduct:workproduct}
					message = {"text": "Request from "+payload.username+" to create task "+name,"attachments": [{"text": "You can Approve or Reject","fallback": "failed to respond","callback_id": "createtask","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approve","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.createtask.adminid, message);
					res.send 'Your request is waiting for approval by '+stdout.createtask.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			#Casual workflow
			else
				createtask.createtask process.env.API, process.env.USERNAME, process.env.PASSWORD, name, workproduct, (error,stdout,stderr) ->
					if(stdout)
						console.log(stdout)
						res.send stdout 
						setTimeout (->eindex.passData stdout),1000
						
					if(stderr)
						console.log(stderr)
						res.send stderr
						setTimeout (->eindex.passData stderr),1000
					
					if(error)
						console.log(error)
						res.send error
						setTimeout (->eindex.passData error),1000
						
	robot.router.post '/createtask', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' for the creating task';
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			name = request.body.name;
			workproduct = request.body.workproduct;
			# Call from create_project file for project creation 
			createtask.createtask process.env.API, process.env.USERNAME, process.env.PASSWORD, name, workproduct, (error,stdout,stderr) ->
				if(stdout)
					console.log(stdout)
					robot.messageRoom data_http.userid, stdout; 
					setTimeout (->eindex.passData stdout),1000
					
				if(stderr)
					console.log(stderr)
					robot.messageRoom data_http.userid, stderr;
					setTimeout (->eindex.passData stderr),1000
				
				if(error)
					console.log(error)
					robot.messageRoom data_http.userid, error;
					setTimeout (->eindex.passData error),1000
		else
			dt="creating task request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to creating task.';
			
	robot.respond /create testcase (.*) workproduct (.*)/, (res) ->
		name=res.match[1]
		workproduct=res.match[2]
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
			if stdout.createtestcase.workflowflag == true
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"createtestcase",name:name,workproduct:workproduct}
					message = {"text": "Request from "+payload.username+" to create testcase "+name,"attachments": [{"text": "You can Approve or Reject","fallback": "failed to respond","callback_id": "createtestcase","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approve","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.createtestcase.adminid, message);
					res.send 'Your request is waiting for approval by '+stdout.createtestcase.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			#Casual workflow
			else
				createtestcase.createtestcase process.env.API, process.env.USERNAME, process.env.PASSWORD, name, workproduct, (error,stdout,stderr) ->
					if(stdout)
						console.log(stdout)
						res.send stdout 
						setTimeout (->eindex.passData stdout),1000
						
					if(stderr)
						console.log(stderr)
						res.send stderr
						setTimeout (->eindex.passData stderr),1000
					
					if(error)
						console.log(error)
						res.send error
						setTimeout (->eindex.passData error),1000
						
	robot.router.post '/createtestcase', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' for the creating testcase';
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			name = request.body.name;
			workproduct = request.body.workproduct
			# Call from create_project file for project creation 
			createtestcase.createtestcase process.env.API, process.env.USERNAME, process.env.PASSWORD, name, workproduct, (error,stdout,stderr) ->
				if(stdout)
					console.log(stdout)
					robot.messageRoom data_http.userid, stdout; 
					setTimeout (->eindex.passData stdout),1000
					
				if(stderr)
					console.log(stderr)
					robot.messageRoom data_http.userid, stderr;
					setTimeout (->eindex.passData stderr),1000
				
				if(error)
					console.log(error)
					robot.messageRoom data_http.userid, error;
					setTimeout (->eindex.passData error),1000
		else
			dt="creating testcase request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to creating testcase.';
	
	robot.respond /create userstory (.*)/, (res) ->
		name=res.match[1]
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
			if stdout.createuserstory.workflowflag == true
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"createuserstory",name:name}
					message = {"text": "Request from "+payload.username+" to create userstory "+name,"attachments": [{"text": "You can Approve or Reject","fallback": "failed to respond","callback_id": "createuserstory","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approve","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.createuserstory.adminid, message);
					res.send 'Your request is waiting for approval by '+stdout.createuserstory.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			#Casual workflow
			else
				createuserstory.createuserstory process.env.API, process.env.USERNAME, process.env.PASSWORD, name, (error,stdout,stderr) ->
					if(stdout)
						console.log(stdout)
						res.send stdout 
						setTimeout (->eindex.passData stdout),1000
						
					if(stderr)
						console.log(stderr)
						res.send stderr
						setTimeout (->eindex.passData stderr),1000
					
					if(error)
						console.log(error)
						res.send error
						setTimeout (->eindex.passData error),1000
						
	robot.router.post '/createuserstory', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' for the creating userstory';
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			name = request.body.name;
			# Call from create_project file for project creation 
			createuserstory.createuserstory process.env.API, process.env.USERNAME, process.env.PASSWORD, name, (error,stdout,stderr) ->
				if(stdout)
					console.log(stdout)
					robot.messageRoom data_http.userid, stdout; 
					setTimeout (->eindex.passData stdout),1000
					
				if(stderr)
					console.log(stderr)
					robot.messageRoom data_http.userid, stderr;
					setTimeout (->eindex.passData stderr),1000
				
				if(error)
					console.log(error)
					robot.messageRoom data_http.userid, error;
					setTimeout (->eindex.passData error),1000
		else
			dt="creating userstory request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to creating userstory.';
				
	robot.respond /create project (.*) in (.*) state (.*)/, (res) ->
		name=res.match[1]
		workspace=res.match[2]
		state=res.match[3]
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
			if stdout.createproject.workflowflag == true
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"createproject",name:name,workspace:workspace,state:state}
					message = {"text": "Request from "+payload.username+" to create project "+name,"attachments": [{"text": "You can Approve or Reject","fallback": "failed to respond","callback_id": "createproject","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approve","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.createproject.adminid, message);
					res.send 'Your request is waiting for approval by '+stdout.createproject.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			#Casual workflow
			else
				createproject.createproject process.env.API, process.env.USERNAME, process.env.PASSWORD, name, workspace, state, (error,stdout,stderr) ->
					if(stdout)
						console.log(stdout)
						res.send stdout 
						setTimeout (->eindex.passData stdout),1000
						
					if(stderr)
						console.log(stderr)
						res.send stderr
						setTimeout (->eindex.passData stderr),1000
					
					if(error)
						console.log(error)
						res.send error
						setTimeout (->eindex.passData error),1000
						
	robot.router.post '/createproject', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' for the creating project';
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			name = request.body.name;
			workspace = request.body.workspace;
			state = request.body.state;
			# Call from create_project file for project creation 
			createproject.createproject process.env.API, process.env.USERNAME, process.env.PASSWORD, name, workspace, state, (error,stdout,stderr) ->
				if(stdout)
					console.log(stdout)
					robot.messageRoom data_http.userid, stdout; 
					setTimeout (->eindex.passData stdout),1000
					
				if(stderr)
					console.log(stderr)
					robot.messageRoom data_http.userid, stderr;
					setTimeout (->eindex.passData stderr),1000
				
				if(error)
					console.log(error)
					robot.messageRoom data_http.userid, error;
					setTimeout (->eindex.passData error),1000
		else
			dt="creating project request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to creating project.';

