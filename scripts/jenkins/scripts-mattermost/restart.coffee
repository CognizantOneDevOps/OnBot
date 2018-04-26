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

#Description:
# restarts jenkins through hubot command
#
#Configuration:
# HUBOT_NAME
# HUBOT_JENKINS_URL
# HUBOT_JENKINS_USER
# HUBOT_JENKINS_PASSWORD
#
#COMMANDS:
# restart jenkins -> restarts jenkins server
#
#Dependencies:
# "request":"2.81.0"
# "elasticSearch": "^0.9.2"

request = require('request')
index = require('./index')
readjson = require './readjson.js'
finaljson=" ";
generate_id = require('./mongoConnt');

module.exports = (robot) ->
	cmd_restart=new RegExp('@' + process.env.HUBOT_NAME + ' restart jenkins')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_restart
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				finaljson=stdout;
				if stdout.restart_jenkins.workflowflag
					generate_id.getNextSequence (err,id) ->
						tckid=id
						console.log(tckid);
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.restart_jenkins.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,callback_id: 'restartjenkins',tckid:tckid};
						data = {"channel": stdout.restart_jenkins.admin,"text":"Request from "+payload.username+" to restart jenkins","message":"Approve Request to restart jenkins",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'restartjenkins',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.restart_jenkins.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						#Insert into Mongo with Payload
						generate_id.add_in_mongo dataToInsert
				else
					#handles regular flow of the command without approval flow
					jenkins_url=process.env.HUBOT_JENKINS_URL
					jenkins_user=process.env.HUBOT_JENKINS_USER
					jenkins_pass=process.env.HUBOT_JENKINS_PASSWORD
					url=jenkins_url+"/restart"
					options = {
					auth: {
						'user': jenkins_user,
						'pass': jenkins_pass
					},
					method: 'POST',
					url: url,
					headers: { } };
					request.post options, (error, response, body) ->
						if(response.statusCode!=302)
							dt="Error! Failed to restart"
							msg.send(dt)
							setTimeout (->index.passData dt),1000
						else
							dt="Restarted Jenkins successfully"
							msg.send(dt)
							setTimeout (->index.passData dt),1000
							message = msg.match[0]
							actionmsg = "restart(s) done for jenkins"
							statusmsg = "Success"
							index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
	)
	#the following code handles the approval flow of the command
	robot.router.post '/restartjenkins', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved restart jenkins request, requested by "+req.body.username+"\n"
			jenkins_url=process.env.HUBOT_JENKINS_URL
			jenkins_user=process.env.HUBOT_JENKINS_USER
			jenkins_pass=process.env.HUBOT_JENKINS_PASSWORD
			url=jenkins_url+"/restart"
			options = {
			auth: {
				'user': jenkins_user,
				'pass': jenkins_pass
			},
			method: 'POST',
			url: url,
			headers: { } };
			request.post options, (error, response, body) ->
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
