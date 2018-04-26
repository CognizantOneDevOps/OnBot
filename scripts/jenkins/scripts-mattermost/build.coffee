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
# Initiates a build for a jenkins job and notifies the user once build is finished
#
#Configuration:
# HUBOT_NAME
# HUBOT_JENKINS_URL
# HUBOT_JENKINS_USER
# HUBOT_JENKINS_PASSWORD
#
#COMMANDS:
# jenkins build <jobname> -> initiate a build for the given jenkins job and notify the user once build is finished
#
#Dependencies:
# "elasticSearch": "^0.9.2"
# "request": "2.81.0"

request = require('request')
index = require('./index')
readjson = require './readjson.js'
finaljson=" ";
statuscheck = require('./statuscheck.coffee')
generate_id = require('./mongoConnt')

module.exports = (robot) ->
	cmd_build=new RegExp('@' + process.env.HUBOT_NAME + ' j(?:enkins)? build (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_build
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				finaljson=stdout;
				job = msg.match[1]
				if stdout.build.workflowflag
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Set APPROVAL_APP_URL
						console.log(tckid);
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.build.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,jobname:job,callback_id: 'jenkinsbuild',tckid:tckid};
						data = {"channel": stdout.build.admin,"text":"Request from "+payload.username+" for jenkins build","message":"Approve Request to build jenkins job named: "+payload.jobname,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'jenkinsbuild',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.build.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						#Insert into Mongo with Payload
						generate_id.add_in_mongo dataToInsert
				else
					#handles regular flow of the command without approval flow
					jenkins_url=process.env.HUBOT_JENKINS_URL
					jenkins_user=process.env.HUBOT_JENKINS_USER
					jenkins_pass=process.env.HUBOT_JENKINS_PASSWORD
					url=jenkins_url+'/job/'+job+'/build'
					options = {
					auth: {
					'user': jenkins_user,
					'pass': jenkins_pass
					},
					method: 'POST',
					url: url};
					request.post options, (error, response, body) ->
						if(response.statusCode!=201)
							dt="Could not initiate build. Make sure the jobname is correct and is not parameterized. Use the following command to start a parameterized build:\nstart <jobname> build with params <param1>=<value1> <param2>=<value2>..."
							msg.send dt
							setTimeout (->index.passData dt),1000
						else
							dt="Build initiated\n"+jenkins_url+'/job/'+job
							msg.send dt
							setTimeout (->index.passData dt),1000
							message = msg.match[0]
							actionmsg = "jenkins build started"
							statusmsg = "Success"
							index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
							statuscheck.checkbuildstatus msg.message.user.room,job
	)
	#the following code handles the approval flow of the command
	robot.router.post '/jenkinsbuild', (req, response) ->
			recipientid=req.body.userid
			if(req.body.action=='Approved')
				dt=req.body.approver+" approved jenkins build for job "+req.body.jobname+", requested by "+req.body.username+"\n"
				job=req.body.jobname
				jenkins_url=process.env.HUBOT_JENKINS_URL
				jenkins_user=process.env.HUBOT_JENKINS_USER
				jenkins_pass=process.env.HUBOT_JENKINS_PASSWORD
				url=jenkins_url+'/job/'+job+'/build'
				options = {
				auth: {
				'user': jenkins_user,
				'pass': jenkins_pass
				},
				method: 'POST',
				url: url};
				request.post options, (error, response, body) ->
					if(response.statusCode!=201)
						dt+="Could not initiate build. Make sure the jobname is correct and is not parameterized. Use the following command to start a parameterized build:\nstart <jobname> build with params <param1>=<value1> <param2>=<value2>..."
						robot.messageRoom recipientid, dt
						setTimeout (->index.passData dt),1000
					else
						dt+="Build initiated\n"+jenkins_url+'/job/'+job
						robot.messageRoom recipientid, dt
						setTimeout (->index.passData dt),1000
						message = "jenkins build "+job
						actionmsg = "jenkins build started"
						statusmsg = "Success"
						index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
						statuscheck.checkbuildstatus recipientid,req.body.jobname
			else
				dt="The build request from "+req.body.username+" was rejected by "+req.body.approver
				robot.messageRoom recipientid, dt
				setTimeout (->index.passData dt),1000
