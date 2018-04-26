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
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,podIp:process.env.MY_POD_IP,"callback_id":"jiracreateissue",Proj_Key:Proj_Key,summary:summary,description:description,issue_type:issue_type}
					message='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: Create jira issue in '+Proj_Key+' of issue type '+issue_type+'\n approve or reject the request'
					robot.messageRoom(stdout.jiracreateissue.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.jiracreateissue.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
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
	#Approval Workflow
	robot.router.post '/jiracreateissue', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approved"
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
					message = 'create jira issue in '+ Proj_Key + ' with summary '+ summary + ' description '+ description + ' and issue type '+ issue_type;
					actionmsg = 'Jira Issue Created';
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
	 
	robot.respond /assign jira issue (.*) to (.*)/i, (msg) ->
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
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,podIp:process.env.MY_POD_IP,"callback_id":"jiraassignissue",assignee:assignee,Jir_ticket:Jir_ticket}
					message='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: Assign jira issue of project '+Jir_ticket+' to '+assignee+'\n approve or reject the request'
					robot.messageRoom(stdout.jiraassignissue.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.jiraassignissue.admin
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
						actionmsg = 'Jira Issue Created';
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
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approved"
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
					message = "Jira Issue Assigned";
					actionmsg = 'Jira ticket assigned';
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
	
	robot.respond /edit jira issue (.*) with description (.*) and comment (.*)/i, (msg) ->
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
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,podIp:process.env.MY_POD_IP,"callback_id":"jiraeditissue",Jir_ticket:Jir_ticket,description:description,comment:comment}
					message='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: Edit jira issue of project '+Jir_ticket+'\n approve or reject the request'
					robot.messageRoom(stdout.jiraeditissue.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.jiraeditissue.admin
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
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approved"
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
					message = 'edit jira issue '+ Jir_ticket + 'with description '+ description + 'and comment '+ comment;
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
			
	robot.respond /add comment (.*) to jira issue (.*)/i, (res) ->
		message = msg.match[0]
		Jir_ticket = res.match[2]
		comment = res.match[1]
		user = res.message.user.name
		# Reading workflow.json file for approval process
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.jiraaddcomment.workflowflag == true
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.reply_to,podIp:process.env.MY_POD_IP,"callback_id":"jiraaddcomment",Jir_ticket:Jir_ticket,comment:comment}
					message='Ticket Id : '+tckid+'\n Raised By: '+res.message.user.name+'\n Command: Add comment to jira issue '+Jir_ticket+'\n approve or reject the request'
					robot.messageRoom(stdout.jiraaddcomment.adminid, message);
					res.send 'Your request is waiting for approval by '+stdout.jiraaddcomment.admin
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
						res.send finalmsg;
						# Send data for wall notification and call from file hubot-elasticsearch-logger/index.js
						actionmsg = 'Comment Posted Successfully';
						statusmsg = 'Success';
						eindex.wallData botname, message, actionmsg, statusmsg;
					else if stderr
						setTimeout (->eindex.passData stderr),1000
						res.send stderr;
					else if error
						setTimeout (->eindex.passData error),1000
						res.send error;
	#Approval Workflow
	robot.router.post '/jiraaddcomment', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		console.log(data_http)
		if data_http.action == 'Approved'
			dt='Your request is approved by '+data_http.approver+' to add comment to Jira issue';
			robot.messageRoom data_http.userid, dt;
			comment = request.body.comment;
			Jir_ticket= request.body.Jir_ticket
			edit_issue.edit_issue jira_url, jira_user, jira_password , comment, Jir_ticket, (error, stdout, stderr) ->
				if stdout
					finalmsg = 'Comment Posted Successfully To Jira Ticket : '.concat(Jir_ticket);
					# Send data to elastic search for logs
					setTimeout (->eindex.passData finalmsg),1000
					robot.messageRoom data_http.userid, 'Comment Posted Successfully To Jira Ticket : '.concat(Jir_ticket);
					message = 'add comment '+ comment + 'to jira issue '+ Jir_ticket;
					actionmsg = 'Comment Posted Successfully';
					statusmsg = 'Success';
					eindex.wallData botname, message, actionmsg, statusmsg;
				else if stderr
					setTimeout (->eindex.passData stderr),1000
					robot.messageRoom data_http.userid, stderr;
				else if error
					setTimeout (->eindex.passData error),1000
					robot.messageRoom data_http.userid, error;
		#Rejection Handled
		else
			dt='Your request is rejected by '+data_http.approver+' to add comment to Jira issue';
			setTimeout (->eindex.passData dt),1000
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to add comment.';
			
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
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,podIp:process.env.MY_POD_IP,"callback_id":"jiraupdatesummary",Jir_ticket:Jir_ticket,summary:summary}
					message='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: Update summary of jira issue '+Jir_ticket+'\n approve or reject the request'
					robot.messageRoom(stdout.jiraupdatesummary.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.jiraupdatesummary.admin
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
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approved"
			dt='Your request is approved by '+data_http.approver+' for updating the Jira issue';
			robot.messageRoom data_http.userid, dt;
			Jir_ticket = request.body.Jir_ticket;
			summary = request.body.summary;
			summary_issue.summary_issue jira_url, jira_user, jira_password , Jir_ticket, summary, (error, stdout, stderr) ->
				if stdout
					finalmsg = 'Summary Updated Successfully To Jira Ticket : '.concat(Jir_ticket);
					setTimeout (->eindex.passData finalmsg),1000
					robot.messageRoom data_http.userid, 'Summary Updated Successfully To Jira Ticket : '.concat(Jir_ticket);
					message = 'update summary of issue '+ Jir_ticket + 'as '+ summary;
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
	# Change the status of issue
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
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,podIp:process.env.MY_POD_IP,"callback_id":"jirachangestatus",Jir_ticket:Jir_ticket,status:status}
					message='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: Change status of jira issue '+Jir_ticket+'\n approve or reject the request'
					robot.messageRoom(stdout.jirachangestatus.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.jirachangestatus.admin
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
	#Approval Workflow
	robot.router.post '/jirachangestatus', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approved"
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
									robot.messageRoom data_http.userid, "Status Changed to #{a[i].name}"
									message = 'change status of issue '+ Jir_ticket + 'to '+ status ;
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
