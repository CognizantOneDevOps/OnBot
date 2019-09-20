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
Set of bot commands
1. Create Issue: create jira issue in <project> with summary <summary> description <description> and issue type <issue_type>
2. Assign Issue: assign jira issue <Project_id> to <user>
3. Add Comment: add comment <comment> to jira issue <project_id>
4. Update Summary: update summary of issue <project_id> as <summary>
5. Status Change: change status of issue <project_id> to <status>
6. Edit Issue: edit jira issue <project_id> with description <desc> and comment <comment>
7. Status to Switch: upcoming status of issue <project_id>

Environment Variable Required
1. HUBOT_JIRA_URL
2. HUBOT_JIRA_USER
3. HUBOT_JIRA_PASSWORD
4. HUBOT_NAME
###

jira_url = process.env.HUBOT_JIRA_URL
jira_user = process.env.HUBOT_JIRA_USER
jira_password =  process.env.HUBOT_JIRA_PASSWORD
pod_ip = process.env.MY_POD_IP
botname = process.env.HUBOT_NAME
# Load Dependencies
eindex = require('./index')
request = require('request')
create_issue = require('./create_issue.js');
edit_issue = require('./edit_issue.js');
edit_desc_issue = require('./edit_desc_issue.js');
summary_issue = require('./summary_issue.js');
update_issue = require('./update_issue.js');
close_issue = require('./close_issue.js');
assign_issue = require('./assign_issue.js');
status_issue = require('./status_issue.js');
transition_issue = require('./transition_issue.js');
issue_desc = require('./issue_desc.js');
show_watchers= require('./show_watchers');
readjson = require ('./readjson.js');
generate_id = require('./mongoConnt');
flag_close = '1';

post = (recipient, data) ->
	options = {method: "POST", url: recipient, json: data}
	request.post options, (error, response, body) ->
		console.log body

module.exports = (robot) ->
	a = []
	flag = 0
	robot.respond /create jira issue in (.*) with summary (.*) description (.*) and issue type (.*)/i, (msg) ->
		message = msg.match[0]
		Proj_Key = msg.match[1]
		summary = msg.match[2]
		description = msg.match[3]
		issue_type = msg.match[4]
		user = msg.message.user.name
		# Reading workflow.json file for approval process
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.jiracreateissue.workflowflag == true
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.jiracreateissue.admin,podIp:process.env.MY_POD_IP,Proj_Key:Proj_Key,summary:summary,description:description,issue_type:issue_type,"callback_id":"jiracreateissue",msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Requested to create issue in project","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": "Request from "+user+" to create jira issue in project "+Proj_Key+" of issue type "+issue_type,"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approved","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}
					#Post attachment to ms teams
					post stdout.jiracreateissue.adminid, data
					msg.send 'Your request is waiting for approval by '+stdout.jiracreateissue.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			#Casual workflow
			else
				create_issue.create_issue jira_url, jira_user, jira_password , Proj_Key, summary, description, issue_type, (error, stdout, stderr) ->
					if stdout
						finalmsg = 'Jira Issue Created Successfully With ID : '.concat(stdout)
						# Send data to elastic search for logs
						setTimeout (->eindex.passData finalmsg),1000
						msg.send finalmsg;
						# Send data for wall notification and call from file hubot-elasticsearch-logger/index.js
						actionmsg = 'Jira Issue Created Successfully';
						statusmsg = 'Success';
						eindex.wallData botname, message, actionmsg, statusmsg;
					else if stderr
						setTimeout (->eindex.passData stderr),1000
						msg.send stderr;
					else if error
						setTimeout (->eindex.passData error),1000
						msg.send error;
	#Approval Workflow
	robot.router.post '/jiracreateissue', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		recipientid=request.body.userid
		dt = {"text":"","title":""}
		if(request.body.action=='Approved')
			dt.title='Your request is approved by '+data_http.approver+' for the creation of Jira issue';
			# Approved Message, send to the user chat room
			Proj_Key = request.body.Proj_Key;
			summary = request.body.summary;
			description = request.body.description;
			issue_type = request.body.issue_type;
			# Call from create_issue file for issue creation 
			create_issue.create_issue jira_url, jira_user, jira_password , Proj_Key, summary, description, issue_type, (error, stdout, stderr) ->
				if stdout
					finalmsg = 'Jira Issue Created Successfully With ID : '.concat(Proj_Key);
					#post the response from bot to teams
					dt.text +=finalmsg
					post recipientid, dt
					# Send data to elastic search for logs
					setTimeout (->eindex.passData finalmsg),1000
					# Send data to elastic search for wall notification
					message = 'create jira issue in '+ Proj_Key + ' with summary '+ summary + ' description '+ description + ' and issue type '+ issue_type;
					actionmsg = 'Jira Issue Created';
					statusmsg = 'Success';
					eindex.wallData botname, message, actionmsg, statusmsg;
				else if stderr
					dt.text+=stderr
					#post the response from bot to teams
					post recipientid, dt
					setTimeout (->eindex.passData dt),1000
				else if error
					dt.text+=error
					#post the response from bot to teams
					post recipientid, dt
					setTimeout (->eindex.passData dt),1000
		else
			dt = {"text":""}
			dt.title = 'Your request is rejected by '+data_http.approver+' for the creation of Jira issue';
			dt.text='Sorry, You are not authorized to create issue.'
			#post the response from bot to teams
			post recipientid, dt
			#response.send dt
			setTimeout (->eindex.passData dt),1000
	
	robot.respond /assign jira issue (.*) to (.*)/i, (msg) ->
		message = msg.match[0];
		Jir_ticket = msg.match[1]
		assignee = msg.match[2]
		user = msg.message.user.name
		# Reading workflow.json file for approval process
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.jiraassignissue.workflowflag == true
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.jiraassignissue.admin,podIp:process.env.MY_POD_IP,assignee:assignee,Jir_ticket:Jir_ticket,"callback_id":"jiraassignissue",msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Requested to assign jira issue ","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": "Request from "+user+" to assign jira issue of project "+Jir_ticket+" to "+assignee,"activitySubtitle":"Requested by: "+payload.username,"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approved","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}
					#Post attachment to ms teams
					post stdout.jiraassignissue.adminid, data
					msg.send  "Your request is Waiting for Approval from **"+stdout.jiraassignissue.admin+"**"
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			#Casual workflow
			else
				assign_issue.assign_issue jira_url, jira_user, jira_password , Jir_ticket, assignee, (error, stdout, stderr) ->
					if stdout
						finalmsg =  'Jira ticket is assigned to: '.concat(assignee);
						# Send data to elastic search for logs
						setTimeout (->eindex.passData finalmsg),1000
						# Send data for wall notification and call from file hubot-elasticsearch-logger/index.js
						msg.send finalmsg;
						actionmsg = 'Jira ticket assigned'
						statusmsg = 'Success';
						eindex.wallData botname, message, actionmsg, statusmsg;
					else if stderr
						setTimeout (->eindex.passData stderr),1000
						msg.send stderr;
					else if error
						setTimeout (->eindex.passData error),1000
						msg.send error;
						
	#Approval Workflow
	robot.router.post '/jiraassignissue', (request, response) ->
		recipientid=request.body.userid
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		dt = {"text":"","title":""}
		if(request.body.action=='Approved')
			dt.title='Your request is approved by '+data_http.approver+' to assign Jira issue';
			Jir_ticket = request.body.Jir_ticket;
			assignee = request.body.assignee;
			assign_issue.assign_issue jira_url, jira_user, jira_password , Jir_ticket, assignee, (error, stdout, stderr) ->
				if stdout
					finalmsg =  'Jira ticket is assigned to: '.concat(assignee);
					#post the response from bot to teams
					post recipientid, finalmsg
					#response.send dt
					setTimeout (->eindex.passData finalmsg),1000
				else if stderr
					dt.text +=stderr
					#post the response from bot to teams
					post recipientid, dt
					#response.send dt
					setTimeout (->eindex.passData dt),1000
				else if error
					dt.text +=error
					#post the response from bot to teams
					post recipientid, dt
					#response.send dt
					setTimeout (->eindex.passData dt),1000
		else
			dt = {"text":""}
			dt.title = 'Your request is approved by '+data_http.approver+' to assign Jira issue';
			dt.text='Sorry, You are not authorized to assign task to assignee.';
			#post the response from bot to teams
			post recipientid, dt
			#response.send dt
			setTimeout (->eindex.passData dt),1000
			
	robot.respond /edit jira issue (.*) with description (.*) and comment (.*)/i, (msg) ->
		message = "Jira Issue Edited";
		Jir_ticket = msg.match[1]
		description = msg.match[2]
		comment = msg.match[3]
		user = msg.message.user.name
		# Reading workflow.json file for approval process
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.jiraeditissue.workflowflag == true
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.jiraeditissue.admin,podIp:process.env.MY_POD_IP,Jir_ticket:Jir_ticket,description:description,comment:comment,"callback_id":"jiraeditissue",msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Requested to edit jira issue of project","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": "Request from "+user+" to edit jira issue of project "+Jir_ticket,"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approved","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}
					#Post attachment to ms teams
					post stdout.jiraeditissue.adminid, data
					msg.send  "Your request is Waiting for Approval from **"+stdout.jiraeditissue.admin+"**"
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			#Casual workflow
			else
				# Call from edit_desc_issue file to edit description as well as comment 
				edit_desc_issue.edit_desc_issue jira_url, jira_user, jira_password , Jir_ticket, description, comment, (error, stdout, stderr) ->
					if stdout
						finalmsg = 'Description and Comment Posted Successfully To Jira Ticket : '.concat(Jir_ticket);
						# Send data to elastic search for logs
						setTimeout (->eindex.passData finalmsg),1000
						msg.send finalmsg;
						# Send data for wall notification and call from file hubot-elasticsearch-logger/index.js
						actionmsg = 'Description and Comment Posted Successfully';
						statusmsg = 'Success';
						eindex.wallData botname, message, actionmsg, statusmsg;
					else if stderr
						setTimeout (->eindex.passData stderr),1000
						msg.send stderr;
					else if error
						setTimeout (->eindex.passData error),1000
						msg.send error;
						
	#Approval Workflow
	robot.router.post '/jiraeditissue', (request, response) ->
		recipientid=request.body.userid
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		dt = {"text":"","title":""}
		if data_http.action == "Approved"
			dt.title='Your request is approved by '+data_http.approver+' for editing Jira issue';
			robot.messageRoom data_http.userid, dt;
			Jir_ticket = request.body.Jir_ticket;
			comment = request.body.comment;
			description = request.body.description;
			edit_desc_issue.edit_desc_issue jira_url, jira_user, jira_password , Jir_ticket, description, comment, (error, stdout, stderr) ->
				if stdout
					finalmsg = 'Description and Comment Posted Successfully To Jira Ticket : '.concat(Jir_ticket);
					dt.text +=finalmsg;
					#post the response from bot to teams
					post recipientid, dt
					#response.send dt
					setTimeout (->eindex.passData dt),1000
					message = 'edit jira issue '+ Jir_ticket + 'with description '+ description + 'and comment '+ comment;
					actionmsg = 'Description and Comment Posted Successfully';
					statusmsg = 'Success';
					eindex.wallData botname, message, actionmsg, statusmsg;
				else if stderr
					dt.text +=stderr;
					setTimeout (->eindex.passData stderr),1000
					post recipientid, dt
				else if error
					dt.text +=error;
					setTimeout (->eindex.passData error),1000
					post recipientid, dt
		else
			dt = {"text":""};
			dt.title ='Your request is rejected by '+data_http.approver+' for editing Jira issue';
			dt.text = 'Sorry, You are not authorized to edit the issue.';
			#post the response from bot to teams
			post recipientid, dt
			#response.send dt
			setTimeout (->eindex.passData dt),1000
			
	robot.respond /add comment (.*) to jira issue (.*)/i, (msg) ->
		message = msg.match[0]
		Jir_ticket = msg.match[2]
		comment = msg.match[1]
		user = msg.message.user.name
		# Reading workflow.json file for approval process
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.jiraaddcomment.workflowflag == true
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.jiraaddcomment.admin,podIp:process.env.MY_POD_IP,Jir_ticket:Jir_ticket,comment:comment,"callback_id":"jiraaddcomment",msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Requested to add comment to jira issue","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": "Request from "+user+" to add comment to jira issue "+Jir_ticket,"activitySubtitle":"Requested by: "+payload.username,"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approved","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}
					#Post attachment to ms teams
					post stdout.jiraaddcomment.adminid, data
					msg.send  "Your request is Waiting for Approval from **"+stdout.jiraaddcomment.admin+"**"
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			#Casual workflow
			else
				# call from edit_issue file for editing
				edit_issue.edit_issue jira_url, jira_user, jira_password , comment, Jir_ticket, (error, stdout, stderr) ->
					if stdout
						finalmsg = 'Comment Posted Successfully To Jira Ticket : '.concat(Jir_ticket);
						# Send data to elastic search for logs
						setTimeout (->eindex.passData finalmsg),1000
						msg.send finalmsg;
						# Send data for wall notification and call from file hubot-elasticsearch-logger/index.js
						actionmsg = 'Comment Posted Successfully';
						statusmsg = 'Success';
						eindex.wallData botname, message, actionmsg, statusmsg;
					else if stderr
						setTimeout (->eindex.passData stderr),1000
						msg.send stderr;
					else if error
						setTimeout (->eindex.passData error),1000
						msg.send error;
						
	#Approval Workflow
	robot.router.post '/jiraaddcomment', (request, response) ->
		recipientid=request.body.userid
		dt = {"text":"","title":""}
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		console.log(data_http)
		if data_http.action == 'Approved'
			dt.title='Your request is approved by '+data_http.approver+' to add comment to Jira issue';
			comment = request.body.comment;
			Jir_ticket= request.body.Jir_ticket
			edit_issue.edit_issue jira_url, jira_user, jira_password , comment, Jir_ticket, (error, stdout, stderr) ->
				if stdout
					finalmsg = 'Comment Posted Successfully To Jira Ticket : '.concat(Jir_ticket);
					# Send data to elastic search for logs
					setTimeout (->eindex.passData finalmsg),1000
					dt.text +=finalmsg
					post recipientid, dt
					message = 'add comment '+ comment + 'to jira issue '+ Jir_ticket;
					actionmsg = 'Comment Posted Successfully To Jira Ticket';
					statusmsg = 'Success';
					eindex.wallData botname, message, actionmsg, statusmsg;
				else if stderr
					setTimeout (->eindex.passData stderr),1000
					robot.messageRoom data_http.userid, stderr;
				else if error
					setTimeout (->eindex.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			dt = {"text":""}
			dt.title = 'Your request is rejected by '+data_http.approver+' to add comment to Jira issue';
			dt.text = 'Sorry, You are not authorized to add comment.';
			#post the response from bot to teams
			post recipientid, dt
			#response.send dt
			setTimeout (->eindex.passData dt),1000
			
	robot.respond /update summary of issue (.*) as (.*)/i, (msg) ->
		message = msg.match[0]
		Jir_ticket = msg.match[1]
		summary = msg.match[2]
		user = msg.message.user.name
		# Reading workflow.json file for approval process
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.jiraupdatesummary.workflowflag == true
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.jiraupdatesummary.admin,podIp:process.env.MY_POD_IP,Jir_ticket:Jir_ticket,summary:summary,"callback_id":"jiraupdatesummary",msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Requested to update summary of jira issue","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": "Request from "+user+" to update summary of jira issue "+Jir_ticket,"activitySubtitle":"Requested by: "+payload.username,"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approved","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}					
					#Post attachment to ms teams
					post stdout.jiraupdatesummary.adminid, data
					msg.send  "Your request is Waiting for Approval from **"+stdout.jiraupdatesummary.admin+"**"
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			#Casual workflow
			else
				# call from summary_issue file to update or change summary of issue
				summary_issue.summary_issue jira_url, jira_user, jira_password , Jir_ticket, summary, (error, stdout, stderr) ->
					if stdout
						finalmsg = 'Summary Updated Successfully To Jira Ticket : '.concat(Jir_ticket);
						# Send data to elastic search for logs
						setTimeout (->eindex.passData finalmsg),1000
						msg.send finalmsg;
						# Send data for wall notification and call from file hubot-elasticsearch-logger/index.js
						actionmsg = 'Summary Updated Successfully';
						statusmsg = 'Success';
						eindex.wallData botname, message, actionmsg, statusmsg;
					else if stderr
						setTimeout (->eindex.passData stderr),1000
						robot.messageRoom data_http.userid, stderr;
					else if error
						setTimeout (->eindex.passData error),1000
						msg.send error;
						
	#Approval Workflow
	robot.router.post '/jiraupdatesummary', (request, response) ->
		recipientid=request.body.userid
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		dt = {"text":"","title":""}
		if data_http.action == "Approved"
			dt.title='Your request is approved by '+data_http.approver+' for updating the Jira issue';
			Jir_ticket = request.body.Jir_ticket;
			summary = request.body.summary;
			summary_issue.summary_issue jira_url, jira_user, jira_password , Jir_ticket, summary, (error, stdout, stderr) ->
				if stdout
					finalmsg = 'Summary Updated Successfully To Jira Ticket : '.concat(Jir_ticket);
					setTimeout (->eindex.passData finalmsg),1000
					dt.text=finalmsg;
					post recipientid, dt
					message = 'update summary of issue '+ Jir_ticket + 'as '+ summary;
					actionmsg = 'Summary Updated Successfully';
					statusmsg = 'Success';
					eindex.wallData botname, message, actionmsg, statusmsg;
				else if stderr
					setTimeout (->eindex.passData stderr),1000
					post recipientid, stderr;
				else if error
					setTimeout (->eindex.passData error),1000
					post recipientid, error;
		else
			dt = {"text":""}
			dt.title = 'Your request is rejected by '+data_http.approver+' for updating the Jira issue';
			dt.text = 'Sorry, You are not authorized to update summary.';
			#post the response from bot to teams
			post recipientid, dt
			#response.send dt
			setTimeout (->eindex.passData dt),1000
			
	robot.respond /upcoming status of issue (.*)/i, (msg) ->
		Jir_ticket = msg.match[1]
		# call from status_issue file to know the upcoming status
		status_issue.status_issue jira_url, jira_user, jira_password , Jir_ticket, (error, stdout, stderr) ->
			response = stdout
			if error
				msg.send "Can't get status."
			else if stderr
				setTimeout (->eindex.passData stderr),1000
				msg.send stderr;
			else if stdout
				length = response.body.transitions.length
				for i in[0...length]
					a[i] = {"name":response.body.transitions[i].name,"id":response.body.transitions[i].id}
				msg.send 'You Can Switch To These Status'
				for i in[0...length]
					msg.send (a[i].name)
					
	robot.respond /change status of issue (.*) to (.*)/i, (msg) ->
		message = msg.match[0]
		Jir_ticket = msg.match[1]
		status = msg.match[2]
		user = msg.message.user.name
		# Reading workflow.json file for approval process
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.jirachangestatus.workflowflag == true
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.jirachangestatus.admin,podIp:process.env.MY_POD_IP,Jir_ticket:Jir_ticket,status:status,"callback_id":"jirachangestatus",msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Requested to change status of jira issue","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": "Request from "+user+" to change status of jira issue "+Jir_ticket,"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approved","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}				
					#Post attachment to ms teams
					post stdout.jirachangestatus.adminid, data
					msg.send  "Your request is Waiting for Approval from **"+stdout.jirachangestatus.admin+"**"
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			#Casual workflow
			else
				# call from status_issue file to know the upcoming status
				status_issue.status_issue jira_url, jira_user, jira_password , Jir_ticket, (error, stdout, stderr) ->
					response = stdout
					if error
						msg.send "Can't go to status.You might not have permission."
					else if stderr
						setTimeout (->eindex.passData stderr),1000
						msg.send stderr;
					else if stdout
						length = response.body.transitions.length
						for i in[0...length]
							a[i] = {"name":response.body.transitions[i].name,"id":response.body.transitions[i].id};
                        #for i in [0...length]
							if (status == a[i].name)
								flag = 1
								status = a[i].id
								#call from transition_issue file to switch the status from existing to new status given by status_issue file
								transition_issue.transition_issue jira_url, jira_user, jira_password , Jir_ticket, status, (error, stdout, stderr) ->
									if (error)
										setTimeout (->eindex.passData error),1000
										msg.send "Status of Jira ticket cannot be changed."
									else
										finalmsg = "Status Changed to #{a[i].name}"
										# Send data to elastic search for logs
										setTimeout (->eindex.passData finalmsg),1000
										msg.send finalmsg;
										# Send data for wall notification and call from file hubot-elasticsearch-logger/index.js
										actionmsg = 'Status Changed';
										statusmsg = 'Success';
										eindex.wallData botname, message, actionmsg, statusmsg;
										
								break
							else
								flag = 0
								
						if (flag == 0)
							msg.send 'You Can Only Switch To The Following Status'
							for i in[0...length]
								msg.send (a[i].name)
								
	#Approval Workflow
	robot.router.post '/jirachangestatus', (request, response) ->
		recipientid=request.body.userid
		dt = {"text":"","title":""}
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approved"
			dt.title='Your request is approved by '+data_http.approver+' to change the status of Jira issue';
			console.log(request.body.status)
			Jir_ticket = request.body.Jir_ticket;
			status = request.body.status;
			status_issue.status_issue jira_url, jira_user, jira_password , Jir_ticket, (error, stdout, stderr) ->
				response = stdout
				if error
					post recipientid, "Can't go to status.You might not have permission."
				else if stderr
					setTimeout (->eindex.passData stderr),1000
					post recipientid, stderr;
				else if stdout
					length = response.body.transitions.length
					for i in[0...length]
						a[i] = {"name":response.body.transitions[i].name,"id":response.body.transitions[i].id}
                    # for i in [0...length]
						if (status == a[i].name)
							flag = 1
							status = a[i].id
							transition_issue.transition_issue jira_url, jira_user, jira_password , Jir_ticket, status, (error, stdout, stderr) ->
								console.log(status);
								if (error)
									setTimeout (->eindex.passData error),1000
									post recipientid, "Status of Jira ticket cannot be changed."
								else if stderr
									setTimeout (->eindex.passData stderr),1000
									post recipientid, stderr;
								else if stdout
									finalmsg = "Status Changed to #{a[i].name}"
									setTimeout (->eindex.passData finalmsg),1000
									dt.text=finalmsg
									post recipientid, dt;
									message = 'change status of issue '+ Jir_ticket + 'to '+ status ;
									actionmsg = 'Status Changed';
									statusmsg = 'Success';
									eindex.wallData botname, message, actionmsg, statusmsg;
							break
						else
							flag = 0							
					if (flag == 0)
						post data_http.userid,'You Can Only Switch To The Following Status'
						for i in[0...length]
							post recipientid, (a[i].name)
		else
			dt = {"text":""}
			dt.title = 'Your request is rejected by '+data_http.approver+' to change the status of Jira issue';
			dt.text = 'Sorry, You are not authorized to change status.';
			#post the response from bot to teams
			post recipientid, dt
			#response.send dt
			setTimeout (->eindex.passData dt),1000
			
	robot.respond /(.*)/i, (msg) ->
		Jir_ticket = msg.match[1]
		# call from issue_status 
		issue_desc.issue_desc jira_url, jira_user, jira_password , Jir_ticket, (result) ->
			if result
				msg.send result
				setTimeout (->eindex.passData result),1000
			else
				msg.send "Couldn't fetch issue details. Please check logs."
				setTimeout (->eindex.passData result),1000
				
	robot.respond /show watchers for (.*)/i, (msg) ->
		Jir_ticket = msg.match[1]
		# call from show_watchers
		show_watchers.show_watchers jira_url, jira_user, jira_password , Jir_ticket, (result) ->
			if result
				msg.send result
				setTimeout (->eindex.passData result),1000
			else
				msg.send "Couldn't fetch issue details. Please check logs."
				setTimeout (->eindex.passData result),1000
