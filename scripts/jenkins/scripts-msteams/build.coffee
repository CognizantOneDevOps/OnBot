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
			
post = (recipient, data) ->
	optons = {method: "POST", url: recipient, json: data}
	request.post optons, (error, response, body) ->
		console.log body

module.exports = (robot) ->
	robot.respond /j(?:enkins)? build (.*)/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			job = msg.match[1]
			url=jenkins_url+'/job/'+job+'/build'
			if stdout.build.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.build.admin,podIp:process.env.MY_POD_IP,jobname:job,"callback_id":"jenkinsbuild",msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Requested to build","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": 'User '+payload.username+' requested to build '+payload.jobname+'\n',"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approved","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}
					#Post attachment to ms teams
					post stdout.build.adminid, data
					msg.send 'Your request is waiting for approval by '+stdout.build.admin
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
						msg.send dt
						setTimeout (->index.passData dt),1000
					else
						dt="Build initiated "+jenkins_url+'job/'+job
						msg.send dt
						setTimeout (->index.passData dt),1000
						message = msg.match[0]
						actionmsg = "jenkins build started"
						statusmsg = "Success"
						index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
						if jenkins_version >= 2.0
#							statuscheck.checkbuildstatus msg.message.user.room,job,crumbvalue
							statuscheck.checkbuildstatus process.env.CURRENT_CHANNEL,job,crumbvalue
						else
							statuscheck.checkbuildstatus process.env.CURRENT_CHANNEL,job,''
	#the following code handles the approval flow of the command
	robot.router.post '/jenkinsbuild', (req, response) ->
			recipientid=req.body.userid
			dt = {"text":"","title":""}
			console.log(req.body)
			if(req.body.action=='Approved')
				dt.title=req.body.approver+" approved jenkins build for job "+req.body.jobname+", requested by "+req.body.username+"\n"
				job=req.body.jobname
				url=jenkins_url+'/job/'+job+'/build'
				options.url = url
				if jenkins_version >= 2.0
					options.headers["Jenkins-Crumb"]=crumbvalue
				else
					options.auth.pass = jenkins_pass
				request.post options, (error, response, body) ->
					if(response.statusCode!=201)
						dt.text="Could not initiate build. Make sure the jobname is correct and is not parameterized. Use the following command to start a parameterized build:\nstart <jobname> build with params <param1>=<value1> <param2>=<value2>..."
						post recipientid, dt
						setTimeout (->index.passData dt),1000
					else
						dt.text="Build initiated\n"+jenkins_url+'/job/'+job
						post recipientid, dt
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
				dt.title="The build request from "+req.body.username+" was rejected by "+req.body.approver
				post recipientid, dt
				setTimeout (->index.passData dt),1000
