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
	cmdcreatebug = new RegExp('@' + process.env.HUBOT_NAME + ' create Bug (.*) Desc (.*) Priority (.*) Severity (.*) and Status (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreatebug
		(res) ->
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
						data = {"channel": stdout.createbug.admin,"text":"Request from "+payload.username+" to create bug "+name,"message":"Request from "+payload.username+" to create bug "+name,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'createbug',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							res.send 'Your request is waiting for approval from '+stdout.createbug.admin
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
	)
					
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

	cmdcreatefeature = new RegExp('@' + process.env.HUBOT_NAME + ' create Feature (.*) Desc (.*) and Status (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreatefeature
		(res) ->
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
						data = {"channel": stdout.createfeature.admin,"text":"Request from "+payload.username+" to create feature "+name,"message":"Request from "+payload.username+" to create feature "+name,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'createfeature',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							res.send 'Your request is waiting for approval from '+stdout.createfeature.admin
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
	)
					
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
			
	
	cmdcreateepic = new RegExp('@' + process.env.HUBOT_NAME + ' create Epic (.*) Desc (.*) and Status (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreateepic
		(res) ->
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
						data = {"channel": stdout.createepic.admin,"text":"Request from "+payload.username+" to create epic "+name,"message":"Request from "+payload.username+" to create epic "+name,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'createepic',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							res.send 'Your request is waiting for approval from '+stdout.createepic.admin
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
	)
						
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
			
	cmdcreateiteration = new RegExp('@' + process.env.HUBOT_NAME + ' create iteration (.*) startdate (.*) Enddate (.*) and Status (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreateiteration
		(res) ->
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
						data = {"channel": stdout.createiteration.admin,"text":"Request from "+payload.username+" to create iteration "+name,"message":"Request from "+payload.username+" to create iteration "+name,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'createiteration',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							res.send 'Your request is waiting for approval from '+stdout.createiteration.admin
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
	)
						
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
			
	cmdcreaterelease= new RegExp('@' + process.env.HUBOT_NAME + ' create release (.*) startdate (.*) Enddate (.*) and Status (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreaterelease
		(res) ->
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
						data = {"channel": stdout.createrelease.admin,"text":"Request from "+payload.username+" to create release "+name,"message":"Request from "+payload.username+" to create release "+name,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'createrelease',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							res.send 'Your request is waiting for approval from '+stdout.createrelease.admin
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
	)
						
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
			
	cmdcreatetask= new RegExp('@' + process.env.HUBOT_NAME + ' create task (.*) workproduct (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreatetask
		(res) ->
			name=res.match[1]
			workproduct=res.match[2]
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				#Action Flow with workflow flag
				if stdout.createtask.workflowflag == true
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"createtask",name:name,workproduct:workproduct}
						data = {"channel": stdout.createtask.admin,"text":"Request from "+payload.username+" to create task "+name,"message":"Request from "+payload.username+" to create task "+name,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'createtask',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							res.send 'Your request is waiting for approval from '+stdout.createtask.admin
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
	)
						
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
			
	cmdcreatetestcase= new RegExp('@' + process.env.HUBOT_NAME + ' create testcase (.*) workproduct (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreatetestcase
		(res) ->
			name=res.match[1]
			workproduct=res.match[2]
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				#Action Flow with workflow flag
				if stdout.createtestcase.workflowflag == true
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"createtestcase",name:name,workproduct:workproduct}
						data = {"channel": stdout.createtestcase.admin,"text":"Request from "+payload.username+" to create testcase "+name,"message":"Request from "+payload.username+" to create testcase "+name,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'createtestcase',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							res.send 'Your request is waiting for approval from '+stdout.createtestcase.admin
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
	)
						
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
	
	cmdcreateuserstory= new RegExp('@' + process.env.HUBOT_NAME + ' create userstory (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreateuserstory
		(res) ->
			name=res.match[1]
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				#Action Flow with workflow flag
				if stdout.createuserstory.workflowflag == true
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"createuserstory",name:name}
						data = {"channel": stdout.createuserstory.admin,"text":"Request from "+payload.username+" to create userstory "+name,"message":"Request from "+payload.username+" to create userstory "+name,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'createuserstory',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							res.send 'Your request is waiting for approval from '+stdout.createuserstory.admin
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
	)
						
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
				
	cmdcreateproject new RegExp('@' + process.env.HUBOT_NAME + ' create project (.*) in (.*) state (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreateproject
		(res) ->
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
						data = {"channel": stdout.createproject.admin,"text":"Request from "+payload.username+" to create project "+name,"message":"Request from "+payload.username+" to create project "+name,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'createproject',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							res.send 'Your request is waiting for approval from '+stdout.createproject.admin
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
	)
						
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

