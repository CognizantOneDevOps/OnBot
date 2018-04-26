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
readjson = require ('./readjson.js');
generate_id = require('./mongoConnt');
flag_close = '1';

module.exports = (robot) ->
	a = []
	flag = 0
	cmdcreate = new RegExp('@' + process.env.HUBOT_NAME + ' create jira issue in (.*) with summary (.*) description (.*) and issue type (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreate
		(msg) ->
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
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.jiracreateissue.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,Proj_Key:Proj_Key,callback_id: 'jiracreateissue',tckid:tckid,summary:summary,description:description,issue_type:issue_type};
						data = {"channel": stdout.jiracreateissue.admin,"text":"Request from " + payload.username + " for creating jira issue with ID: "+payload.Proj_Key,"message":"Request from " + payload.username + " to create jira issue with ID: "+payload.Proj_Key,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'jiracreateissue',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							msg.send 'Your request is waiting for approval from '+stdout.jiracreateissue.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Casual workflow
				else
					create_issue.create_issue jira_url, jira_user, jira_password , Proj_Key, summary, description, issue_type, (error, stdout, stderr) ->
						if stdout
							finalmsg = 'Jira Issue Created Successfully With ID : '.concat(Proj_Key);
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
	)
	#Approval Workflow
	robot.router.post '/jiracreateissue', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' for the creation of Jira issue';
			# Approved Message, send to the user chat room
			robot.messageRoom data_http.userid, dt;
			Proj_Key = request.body.Proj_Key;
			summary = request.body.summary;
			description = request.body.description;
			issue_type = request.body.issue_type;
			# Call from create_issue file for issue creation
			create_issue.create_issue jira_url, jira_user, jira_password , Proj_Key, summary, description, issue_type, (error, stdout, stderr) ->
				if stdout
					finalmsg = 'Jira Issue Created Successfully With ID : '.concat(Proj_Key);
					# Send data to elastic search for logs
					setTimeout (->eindex.passData finalmsg),1000
					robot.messageRoom data_http.userid, finalmsg;
					# Send data to elastic search for wall notification
					message = 'create jira issue in '+ Proj_Key + ' with summary '+summary+' description '+description+' and issue type '+issue_type
					actionmsg = 'Jira Issue Created Successfully'
					statusmsg = 'Success';
					eindex.wallData botname, message, actionmsg, statusmsg;
				else if stderr
					setTimeout (->eindex.passData stderr),1000
					robot.messageRoom data_http.userid, stderr;
				else if error
					setTimeout (->eindex.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			dt='Your request is rejected by '+data_http.approver+' for the creation of Jira issue';
			setTimeout (->eindex.passData dt),1000
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to create issue.';
	
	cmdassign = new RegExp('@' + process.env.HUBOT_NAME + ' assign jira issue (.*) to (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdassign
		(msg) ->
			message = msg.match[0]
			Jir_ticket = msg.match[1]
			assignee = msg.match[2]
			user = msg.message.user.name
			# Reading workflow.json file for approval process
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.jiraassignissue.workflowflag == true
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.jiraassignissue.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,Jir_ticket:Jir_ticket,callback_id: 'jiraassignissue',tckid:tckid,assignee:assignee};
						data = {"channel": stdout.jiraassignissue.admin,"text":"Request from " + payload.username + " for assigning jira issue with ID: "+payload.Jir_ticket,"message":"Request from " + payload.username + " to assign jira issue with ID: "+payload.Jir_ticket,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'jiraassignissue',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '+stdout.jiraassignissue.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
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
	)
	#Approval Workflow
	robot.router.post '/jiraassignissue', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' to assign Jira issue';
			robot.messageRoom data_http.userid, dt;
			Jir_ticket = request.body.Jir_ticket;
			assignee = request.body.assignee;
			# Call from assign_issue file to assign issue 
			assign_issue.assign_issue jira_url, jira_user, jira_password , Jir_ticket, assignee, (error, stdout, stderr) ->
				if stdout
					finalmsg =  'Jira ticket is assigned to: '.concat(assignee);
					# Send data to elastic search for logs
					setTimeout (->eindex.passData finalmsg),1000
					robot.messageRoom data_http.userid, finalmsg;
					message = 'assign jira issue '+ Jir_ticket + ' to '+ assignee;
					actionmsg = 'Jira ticket assigned'
					statusmsg = 'Success';
					eindex.wallData botname, message, actionmsg, statusmsg;
				else if stderr
					setTimeout (->eindex.passData stderr),1000
					robot.messageRoom data_http.userid, stderr;
				else if error
					setTimeout (->eindex.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			dt='Your request is approved by '+data_http.approver+' to assign Jira issue';
			setTimeout (->eindex.passData dt),1000
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to assign task to assignee.';
	
	cmdeditissue = new RegExp('@' + process.env.HUBOT_NAME + ' edit jira issue (.*) with description (.*) and comment (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdeditissue
		(msg) ->
			message = msg.match[0]
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
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.jiraeditissue.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,Jir_ticket:Jir_ticket,callback_id: 'jiraeditissue',tckid:tckid,description:description,comment:comment};
						data = {"channel": stdout.jiraeditissue.admin,"text":"Request from " + payload.username + " for editing jira issue with ID: "+payload.Jir_ticket,"message":"Request from " + payload.username + " to edit jira issue with ID: "+payload.Jir_ticket,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'jiraeditissue',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '+stdout.jiraeditissue.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
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
	)
	#Approval Workflow
	robot.router.post '/jiraeditissue', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' for editing Jira issue';
			robot.messageRoom data_http.userid, dt;
			Jir_ticket = request.body.Jir_ticket;
			comment = request.body.comment;
			description = request.body.description;
			edit_desc_issue.edit_desc_issue jira_url, jira_user, jira_password , Jir_ticket, description, comment, (error, stdout, stderr) ->
				if stdout
					finalmsg = 'Description and Comment Posted Successfully To Jira Ticket : '.concat(Jir_ticket);
					setTimeout (->eindex.passData finalmsg),1000
					robot.messageRoom data_http.userid, finalmsg;
					message = 'edit jira issue '+ Jir_ticket +' with description '+ description +' and comment '+ comment;
					actionmsg = 'Description and Comment Posted Successfully';
					statusmsg = 'Success';
					eindex.wallData botname, message, actionmsg, statusmsg;
				else if stderr
					setTimeout (->eindex.passData stderr),1000
					robot.messageRoom data_http.userid, stderr;
				else if error
					setTimeout (->eindex.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			dt='Your request is rejected by '+data_http.approver+' for editing Jira issue';
			setTimeout (->eindex.passData dt),1000
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to edit the issue.';
	
	cmdaddcomment = new RegExp('@' + process.env.HUBOT_NAME + ' add comment (.*) to jira issue (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdaddcomment
		(res) ->
			message = res.match[0]
			Jir_ticket = res.match[2]
			comment = res.match[1]
			user = res.message.user.name
			# Reading workflow.json file for approval process
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				if stdout.jiraaddcomment.workflowflag == true
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.room,approver:stdout.jiraaddcomment.admin,podIp:process.env.MY_POD_IP,message:res.message.text,Jir_ticket:Jir_ticket,callback_id: 'jiraaddcomment',tckid:tckid,comment:comment};
						data = {"channel": stdout.jiraaddcomment.admin,"text":"Request from " + payload.username + " for adding comment to jira issue with ID: "+payload.Jir_ticket,"message":"Request to add comment to jira issue with ID: "+payload.Jir_ticket,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'jiraaddcomment',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						res.send 'Your request is waiting for approval from '+stdout.jiraaddcomment.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Casual workflow
				else
					# call from edit_issue file for editing
					edit_issue.edit_issue jira_url, jira_user, jira_password , comment, Jir_ticket, (error, stdout, stderr) ->
						if stdout
							finalmsg = 'Comment Posted Successfully To Jira Ticket : '.concat(Jir_ticket);
							# Send data to elastic search for logs
							setTimeout (->eindex.passData finalmsg),1000
							res.send finalmsg;
							# Send data for wall notification and call from file hubot-elasticsearch-logger/index.js
							actionmsg = 'Comment Posted Successfully'
							statusmsg = 'Success';
							eindex.wallData botname, message, actionmsg, statusmsg;
						else if stderr
							setTimeout (->eindex.passData stderr),1000
							res.send stderr;
						else if error
							setTimeout (->eindex.passData error),1000
							res.send error;
	)
	#Approval Workflow
	robot.router.post '/jiraaddcomment', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		console.log(data_http)
		if data_http.action == 'Approve'
			dt='Your request is approved by '+data_http.approver+' to add comment to Jira issue';
			robot.messageRoom data_http.userid, dt;
			comment = request.body.comment;
			Jir_ticket= request.body.Jir_ticket
			edit_issue.edit_issue jira_url, jira_user, jira_password , comment, Jir_ticket, (error, stdout, stderr) ->
				if stdout
					finalmsg = 'Comment Posted Successfully To Jira Ticket : '.concat(Jir_ticket);
					# Send data to elastic search for logs
					setTimeout (->eindex.passData finalmsg),1000
					robot.messageRoom data_http.userid, finalmsg;
					message = 'add comment '+ comment + ' to jira issue '+ Jir_ticket;
					actionmsg = 'Comment Posted Successfully';
					statusmsg = 'Success';
					eindex.wallData botname, message, actionmsg, statusmsg;
				else if stderr
					setTimeout (->eindex.passData stderr),1000
					robot.messageRoom data_http.userid, stderr;
				else if error
					setTimeout (->eindex.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			dt='Your request is rejected by '+data_http.approver+' to add comment to Jira issue';
			setTimeout (->eindex.passData dt),1000
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to add comment.';
			
	cmdupdatesummary = new RegExp('@' + process.env.HUBOT_NAME + ' update summary of issue (.*) as (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdupdatesummary
		(msg) ->
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
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.jiraupdatesummary.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,Jir_ticket:Jir_ticket,callback_id: 'jiraupdatesummary',tckid:tckid,summary:summary};
						data = {"channel": stdout.jiraupdatesummary.admin,"text":"Request from " + payload.username + " for updating summary to jira issue with ID: "+payload.Jir_ticket,"message":"Request to update summary "+payload.summary+" to jira issue with ID: "+payload.Jir_ticket,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'jiraupdatesummary',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '+stdout.jiraupdatesummary.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
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
	)
	#Approval Workflow
	robot.router.post '/jiraupdatesummary', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' for updating the Jira issue';
			robot.messageRoom data_http.userid, dt;
			Jir_ticket = request.body.Jir_ticket;
			summary = request.body.summary;
			summary_issue.summary_issue jira_url, jira_user, jira_password , Jir_ticket, summary, (error, stdout, stderr) ->
				if stdout
					finalmsg = 'Summary Updated Successfully To Jira Ticket : '.concat(Jir_ticket);
					setTimeout (->eindex.passData finalmsg),1000
					robot.messageRoom data_http.userid, finalmsg;
					message = 'update summary of issue '+ Jir_ticket + ' as '+summary;
					actionmsg = 'Summary Updated Successfully';
					statusmsg = 'Success';
					eindex.wallData botname, message, actionmsg, statusmsg;
				else if stderr
					setTimeout (->eindex.passData stderr),1000
					robot.messageRoom data_http.userid, stderr;
				else if error
					setTimeout (->eindex.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			dt='Your request is rejected by '+data_http.approver+' for updating the Jira issue';
			setTimeout (->eindex.passData dt),1000
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to update summary.';
		
	cmdstatusupcoming = new RegExp('@' + process.env.HUBOT_NAME + ' upcoming status of issue (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdstatusupcoming
		(msg) ->
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
					msg.send "Issue Status Is: " + response.body.fields.status.name
					for i in[0...length]
						a[i] = {"name":response.body.transitions[i].name,"id":response.body.transitions[i].id}
					temp = " You Can Switch To One Of These Status : "
					for i in[0...length]
						if i == length-1
							temp+=(a[i].name)
						else
							temp+=(a[i].name + " , ")				
					msg.send temp
	)
	
	cmdchangestatus = new RegExp('@' + process.env.HUBOT_NAME + ' change status of issue (.*) to (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdchangestatus
		(msg) ->
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
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.jirachangestatus.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,Jir_ticket:Jir_ticket,callback_id: 'jirachangestatus',tckid:tckid,status:status};
						data = {"channel": stdout.jirachangestatus.admin,"text":"Request from " + payload.username + " for changing status of jira issue with ID: "+payload.Jir_ticket,"message":"Request to change status of jira issue with ID: "+payload.Jir_ticket,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'jirachangestatus',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '+stdout.jirachangestatus.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
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
								a[i] = {"name":response.body.transitions[i].name,"id":response.body.transitions[i].id}
							for i in [0...length]
								if (status == a[i].name)
									flag = 1
									status = a[i].id
									# call from transition_issue file to switch the status from existing to new status given by status_issue file
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
	)
	#Approval Workflow
	robot.router.post '/jirachangestatus', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' to change the status of Jira issue';
			robot.messageRoom data_http.userid, dt;
			console.log(request.body.status)
			Jir_ticket = request.body.Jir_ticket;
			status = request.body.status;
			status_issue.status_issue jira_url, jira_user, jira_password , Jir_ticket, (error, stdout, stderr) ->
				response = stdout
				if error
					robot.messageRoom data_http.userid, "Can't go to status.You might not have permission."
				else if stderr
					setTimeout (->eindex.passData stderr),1000
					robot.messageRoom data_http.userid, stderr;
				else if stdout
					length = response.body.transitions.length
					for i in[0...length]
						a[i] = {"name":response.body.transitions[i].name,"id":response.body.transitions[i].id}
					for i in [0...length]
						if (status == a[i].name)
							flag = 1
							status = a[i].id
							transition_issue.transition_issue jira_url, jira_user, jira_password , Jir_ticket, status, (error, stdout, stderr) ->
								console.log(status);
								if (error)
									setTimeout (->eindex.passData error),1000
									robot.messageRoom data_http.userid, "Status of Jira ticket cannot be changed."
								else if stderr
									setTimeout (->eindex.passData stderr),1000
									robot.messageRoom data_http.userid, stderr;
								else if stdout
									finalmsg = "Status Changed to #{a[i].name}"
									setTimeout (->eindex.passData finalmsg),1000
									robot.messageRoom data_http.userid, finalmsg;
									message = 'change status of issue '+Jir_ticket+' to '+status;
									actionmsg = 'Status Changed';
									statusmsg = 'Success';
									eindex.wallData botname, message, actionmsg, statusmsg;
							break
						else
							flag = 0
					if (flag == 0)
						robot.messageRoom data_http.userid,'You Can Only Switch To The Following Status'
						for i in[0...length]
							robot.messageRoom data_http.userid, (a[i].name)
		else
			dt='Your request is rejected by '+data_http.approver+' to change the status of Jira issue';
			setTimeout (->eindex.passData dt),1000
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to change status.';
