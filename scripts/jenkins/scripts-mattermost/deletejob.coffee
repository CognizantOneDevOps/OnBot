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
# deletes the given jenkins job
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
# delete job <jobname> -> delete the given jenkins job
#
#Description:
# "elasticSearch": "^0.9.2"
# "request": "2.81.0"

jenkins_url=process.env.HUBOT_JENKINS_URL
jenkins_user=process.env.HUBOT_JENKINS_USER
jenkins_pass=process.env.HUBOT_JENKINS_PASSWORD
jenkins_api=process.env.HUBOT_JENKINS_API_TOKEN
jenkins_version=process.env.HUBOT_JENKINS_VERSION

request = require('request')
index = require('./index')
readjson = require './readjson.js'
finaljson=" ";
generate_id = require('./mongoConnt')
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
	cmd_delete=new RegExp('@' + process.env.HUBOT_NAME + ' delete job (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmd_delete
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				#reading workflow.json
				finaljson=stdout;
				jobname=msg.match[1]
				if stdout.delete_job.workflowflag
					generate_id.getNextSequence (err,id) ->
						tckid=id
						#Set APPROVAL_APP_URL
						console.log(tckid);
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.delete_job.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,jobname:jobname,callback_id: 'jenkinsdelete',tckid:tckid};
						data = {"channel": stdout.delete_job.admin,"text":"Request from "+payload.username+" to delete jenkins job","message":"Approve Request for deleting jenkins job named: "+payload.jobname,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'jenkinsdelete',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						attach_opt = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post attach_opt, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '.concat(stdout.delete_job.admin);
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						#Insert into Mongo with Payload
						generate_id.add_in_mongo dataToInsert
				else
					#handles regular flow of the command without approval flow
					jobname=msg.match[1]
					url=jenkins_url+"/job/"+jobname+"/doDelete"
					options.url = url
					if jenkins_version >= 2.0
						options.headers["Jenkins-Crumb"]=crumbvalue
					else
						options.auth.pass = jenkins_pass
					request.post options, (error, response, body) ->
						if(response.statusCode!=302)
							dt="Job not found. Make sure you spell the jobname correctly"
							msg.send(dt)
							setTimeout (->index.passData dt),1000
						else
							dt="job deleted"
							msg.send(dt)
							setTimeout (->index.passData dt),1000
							message = msg.match[0]
							actionmsg = "jenkins job deleted"
							statusmsg = "Success"
							index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
	)
	#the following code handles the approval flow of the command
	robot.router.post '/jenkinsdelete', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved jenkins job "+req.body.jobname+" deletion request from "+req.body.username+"\n"
			jobname=req.body.jobname
			url=jenkins_url+"/job/"+jobname+"/doDelete"
			options.url = url
			if jenkins_version >= 2.0
				options.headers["Jenkins-Crumb"]=crumbvalue
			else
				options.auth.pass = jenkins_pass
			request.post options, (error, response, body) ->
				if(response.statusCode!=302)
					dt+="Job not found. Make sure you spell the jobname correctly"
					robot.messageRoom recipientid, dt
					setTimeout (->index.passData dt),1000
				else
					dt+="job deleted"
					robot.messageRoom recipientid, dt
					setTimeout (->index.passData dt),1000
					message = "delete job "+jobname
					actionmsg = "jenkins job deleted"
					statusmsg = "Success"
					index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
		else
			dt="The delete request from "+req.body.username+" was rejected by "+req.body.approver
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
