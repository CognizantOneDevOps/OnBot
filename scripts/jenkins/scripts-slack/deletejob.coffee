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
			headers: {},
			};
if jenkins_version >= 2.0
	crumb.crumb (stderr, stdout) ->
		console.log stdout
		if(stdout)
			crumbvalue=stdout
module.exports = (robot) ->
	robot.respond /delete job (.*)/i, (res) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			#reading workflow.json
			finaljson=stdout;
			jobname=res.match[1]
			if stdout.delete_job.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					
					payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.room,approver:stdout.delete_job.admin,podIp:process.env.MY_POD_IP,jobname:jobname,callback_id: 'jenkinsdelete',msg:res.toString()}
					data = {text: 'Approve Request',attachments: [{text: 'slack user '+payload.username+' requested to delete the following job:\n'+payload.jobname,fallback: 'Yes or No?',callback_id: 'jenkinsdelete',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approved', text: 'Approved', type: 'button', value: tckid,confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Approve','dismiss_text': 'Cancel'} },{ name: 'Rejected', text: 'Rejected',  type: 'button',  value: tckid,'style':'danger',confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Reject','dismiss_text': 'Cancel'}}]}]}
					robot.messageRoom stdout.delete_job.adminid, data
					res.send  "You request is Waiting for Approval from "+stdout.delete_job.admin;
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				#handles regular flow of the command without approval flow
				jobname=res.match[1]
				url=jenkins_url+"/job/"+jobname+"/doDelete"
				options.url=url
				if jenkins_version >= 2.0
					options.headers["Jenkins-Crumb"]=crumbvalue
				else
					options.auth.pass = jenkins_pass
				request.post options, (error, response, body) ->
					if(response.statusCode!=302)
						dt="Job not found. Make sure you spell the jobname correctly"
						res.send(dt)
						setTimeout (->index.passData dt),1000
					else
						dt="job deleted"
						res.send(dt)
						setTimeout (->index.passData dt),1000
						message = res.match[0]
						actionmsg = "jenkins job deleted"
						statusmsg = "Success"
						index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
	#the following code handles the approval flow of the command
	robot.router.post '/jenkinsdelete', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved jenkins job "+req.body.jobname+" deletion request from "+req.body.username+"\n"
			jobname=req.body.jobname
			jenkins_url=process.env.HUBOT_JENKINS_URL
			jenkins_user=process.env.HUBOT_JENKINS_USER
			jenkins_pass=process.env.HUBOT_JENKINS_PASSWORD
			url=jenkins_url+"/job/"+jobname+"/doDelete"
			options.url=url
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
