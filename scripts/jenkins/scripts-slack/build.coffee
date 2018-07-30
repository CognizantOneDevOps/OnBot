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
# Initiates a build for a jenkins job and notifies the user once build is finished
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
# jenkins build <jobname> -> initiate a build for the given jenkins job and notify the user once build is finished
#
#Dependencies:
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
statuscheck = require('./statuscheck.coffee')
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
		console.log stdout
		if(stdout)
			crumbvalue=stdout

module.exports = (robot) ->
	robot.respond /j(?:enkins)? build (.*)/i, (res) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			job = res.match[1]
			url=jenkins_url+'/job/'+job+'/build'
			if stdout.build.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.room,approver:stdout.build.admin,podIp:process.env.MY_POD_IP,jobname:job,callback_id:'jenkinsbuild',msg:res.toString()}
					data = {text: 'Approve Request',attachments: [{text: 'slack user '+payload.username+' requested to build '+payload.jobname+'\n',fallback: 'Yes or No?',callback_id: 'jenkinsbuild',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approved', text: 'Approved', type: 'button', value: tckid,confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Approve','dismiss_text': 'Cancel'} },{ name: 'Rejected', text: 'Rejected',  type: 'button',  value: tckid,'style':'danger',confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Reject','dismiss_text': 'Cancel'}}]}]}
					robot.messageRoom stdout.build.adminid, data
					res.send  "You request is Waiting for Approval from "+stdout.build.admin;
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				#handles regular flow of the command without approval flow
				options.url = url
				if jenkins_version >= 2.0
					options.headers["Jenkins-Crumb"]=crumbvalue
				else
					options.auth.pass = jenkins_pass
				console.log options
				request.post options, (error, response, body) ->
					if(response.statusCode!=201)
						dt="Could not initiate build. Make sure the jobname is correct and is not parameterized. Use the following command to start a parameterized build:\nstart <jobname> build with params <param1>=<value1> <param2>=<value2>..."
						res.send dt
						setTimeout (->index.passData dt),1000
					else
						dt="Build initiated\n"+jenkins_url+'/job/'+job
						res.send dt
						setTimeout (->index.passData dt),1000
						message = res.match[0]
						actionmsg = "jenkins build started"
						statusmsg = "Success"
						index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
						if jenkins_version >= 2.0
							statuscheck.checkbuildstatus res.message.user.room,job,crumbvalue
						else
							statuscheck.checkbuildstatus res.message.user.room,job,''
	#the following code handles the approval flow of the command
	robot.router.post '/jenkinsbuild', (req, response) ->
			recipientid=req.body.userid
			console.log(req.body)
			if(req.body.action=='Approved')
				dt=req.body.approver+" approved jenkins build for job "+req.body.jobname+", requested by "+req.body.username+"\n"
				job=req.body.jobname
				url=jenkins_url+'/job/'+job+'/build'
				options.url = url
				if jenkins_version >= 2.0
					options.headers["Jenkins-Crumb"]=crumbvalue
				else
					options.auth.pass = jenkins_pass
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
						if jenkins_version >= 2.0
							statuscheck.checkbuildstatus recipientid,job,crumbvalue
						else
							statuscheck.checkbuildstatus recipientid,job,''
			else
				dt="The build request from "+req.body.username+" was rejected by "+req.body.approver
				robot.messageRoom recipientid, dt
				setTimeout (->index.passData dt),1000
