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
# restarts jenkins through hubot command
#
#Configuration:
# HUBOT_NAME
# HUBOT_JENKINS_URL
# HUBOT_JENKINS_USER
# HUBOT_JENKINS_PASSWORD
# HUBOT_JENKINS_API_TOKEN
# HUBOT_JENKINS_VERSION
#
#COMMANDS:
# restart jenkins -> restarts jenkins server
#
#Dependencies:
# "request":"2.81.0"
# "elasticSearch": "^0.9.2"

jenkins_url=process.env.HUBOT_JENKINS_URL
jenkins_user=process.env.HUBOT_JENKINS_USER
jenkins_pass=process.env.HUBOT_JENKINS_PASSWORD
jenkins_api=process.env.HUBOT_JENKINS_API_TOKEN
jenkins_version=process.env.HUBOT_JENKINS_VERSION

request = require('request')
index = require('./index')
readjson = require './readjson.js'
finaljson=" ";
generate_id = require('./mongoConnt');
crumb = require('./jenkinscrumb.js')

crumbvalue = ''
options = {
url: '',
auth: {
'user': jenkins_user,
'pass': jenkins_api
},
method: 'POST',
headers:{}};
if jenkins_version >= 2.0
	crumb.crumb (stderr, stdout) ->
		if(stdout)
			crumbvalue=stdout

module.exports = (robot) ->
	robot.respond /restart jenkins/i, (res) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			if stdout.restart_jenkins.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					
					payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.room,approver:stdout.restart_jenkins.admin,podIp:process.env.MY_POD_IP,callback_id: 'restartjenkins',msg:res.toString()}
					data = {text: 'Approve Request',attachments: [{text: 'slack user '+payload.username+' requested to restart jenkins\n',fallback: 'Yes or No?',callback_id: 'restartjenkins',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approved', text: 'Approved', type: 'button', value: tckid,confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Approve','dismiss_text': 'Cancel'} },{ name: 'Rejected', text: 'Rejected',  type: 'button',  value: tckid,'style':'danger',confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Reject','dismiss_text': 'Cancel'}}]}]}
					robot.messageRoom stdout.restart_jenkins.adminid, data
					res.send  "You request is Waiting for Approval from "+stdout.restart_jenkins.admin;
					
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				#handles regular flow of the command without approval flow
				url=jenkins_url+"/restart"
				options.url = url
				if jenkins_version >= 2.0
					options.headers["Jenkins-Crumb"]=crumbvalue
				else
					options.auth.pass = jenkins_pass
				request.post options, (error, response, body) ->
					console.log(response.body)
					if(response.statusCode!=302)
						dt="Error! Failed to restart"
						res.send(dt)
						setTimeout (->index.passData dt),1000
					else
						dt="Restarted Jenkins successfully"
						res.send(dt)
						setTimeout (->index.passData dt),1000
						message = res.match[0]
						actionmsg = "restart(s) done for jenkins"
						statusmsg = "Success"
						index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
	#the following code handles the approval flow of the command
	robot.router.post '/restartjenkins', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved restart jenkins request, requested by "+req.body.username+"\n"
			jenkins_url=process.env.HUBOT_JENKINS_URL
			jenkins_user=process.env.HUBOT_JENKINS_USER
			jenkins_pass=process.env.HUBOT_JENKINS_PASSWORD
			url=jenkins_url+"/restart"
			options.url = url
			if jenkins_version >= 2.0
					options.headers["Jenkins-Crumb"]=crumbvalue
				else
					options.auth.pass = jenkins_pass
			request.post options, (error, response, body) ->
				console.log(response.body)
				if(response.statusCode!=302)
					dt+="Error! Failed to restart"
					robot.messageRoom recipientid, dt
					setTimeout (->index.passData dt),1000
				else
					dt+="Restarted Jenkins successfully"
					robot.messageRoom recipientid, dt
					setTimeout (->index.passData dt),1000
					message = "restart jenkins"
					actionmsg = "restart(s) done for jenkins"
					statusmsg = "Success"
					index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
		else
			dt="The jenkins restart request from "+req.body.username+" was rejected by "+req.body.approver
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
