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
# creates a jenkins job with the configuration in the given config.xml
# config.xml has to be created by user, ensure it is errorfree and adheres to jenkins standards for a config.xml fileData
#
#Configuration:
# HUBOT_NAME
# HUBOT_JENKINS_URL
# HUBOT_JENKINS_USER
# HUBOT_JENKINS_PASSWORD
# HUBOT_JENKINS_API_TOKEN
#
#COMMANDS:
# create job <jobname> with <full_config_name_with_extension> -> creates a jenkins job with the given config.xml file
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
fs = require('fs')
index = require('./index')
readjson = require('./readjson.js')
crumb = require('./jenkinscrumb.js')
finaljson=" "
generate_id = require('./mongoConnt')
crumbvalue = ''
url=jenkins_url+"/createItem?name="
options = {
			url: url,
			auth: {
			'user': jenkins_user,
			'pass': jenkins_api
			},
			method: 'POST',
			headers: {"Content-Type":"text/xml"},
			};
if jenkins_version >= 2.0
	crumb.crumb (stderr, stdout) ->
		console.log stdout
		if(stdout)
			crumbvalue=stdout

module.exports = (robot) ->
	robot.respond /create job (.*) with (.*)/i, (res) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			#reading workflow.json
			finaljson=stdout;
			jobname=res.match[1]
			options.url = url+jobname
			if stdout.create_job.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					
					payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.room,approver:stdout.create_job.admin,podIp:process.env.MY_POD_IP,jobname:jobname,userxml:res.match[2],callback_id: 'jenkinscreate',msg:res.toString()}
					data = {text: 'Approve Request',attachments: [{text: 'slack user '+payload.username+' requested to create the following job:\n'+payload.jobname+' with '+payload.userxml,fallback: 'Yes or No?',callback_id: 'jenkinscreate',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approved', text: 'Approved', type: 'button', value: tckid,confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Approve','dismiss_text': 'Cancel'} },{ name: 'Rejected', text: 'Rejected',  type: 'button',  value: tckid,'style':'danger',confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Reject','dismiss_text': 'Cancel'}}]}]}
					robot.messageRoom stdout.create_job.adminid, data
					res.send  "You request is Waiting for Approval from "+stdout.create_job.admin;
					
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				#handles regular flow of the command without approval flow
				jobname=res.match[1]
				user_xml=res.match[2]
				
				fs.readFile './scripts/'+user_xml, 'utf8', (err, fileData) ->
					if(err)
						dt="Error in reading XML: " +err
						res.send(dt)
						setTimeout (->index.passData dt),1000
					else
						options.body = fileData
						if jenkins_version >= 2.0
							options.headers["Jenkins-Crumb"]=crumbvalue
						else
							options.auth.pass = jenkins_pass
						console.log options
						request.post(options, (error, response, body) ->
							console.log("*****************"+error);
							console.log(body);
							if(response.statusCode==200)
								dt="Job created successfully with the given configuration"
								res.send dt
								setTimeout (->index.passData dt),1000
								message = res.match[0]
								actionmsg = "jenkins job created"
								statusmsg = "Success"
								index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
							else
								dt="Could not create job. Please try again"
								res.send dt
								setTimeout (->index.passData dt),1000
						)
		#the following code handles the approval flow of the command
		robot.router.post '/jenkinscreate', (req, response) ->
			recipientid=req.body.userid
			if(req.body.action=='Approved')
				dt=req.body.approver+" approved creation of jenkins job "+req.body.jobname+", requested by "+req.body.username+"\n"
				jobname=req.body.jobname
				user_xml="./scripts/"+req.body.userxml
				
				fs.readFile user_xml, 'utf8', (err, fileData) ->
					if(err)
						dt+="Error in reading XML: " +err
						robot.messageRoom recipientid, dt
						setTimeout (->index.passData dt),1000
					else
						options.url = url+jobname
						options.body = fileData
						if jenkins_version >= 2.0
							options.headers["Jenkins-Crumb"]=crumbvalue
						else
							options.auth.pass = jenkins_pass
						request.post(options, (error, response, body) ->
							if(response.statusCode==200)
								dt+="Job created successfully with the given configuration"
								robot.messageRoom recipientid, dt
								setTimeout (->index.passData dt),1000
								message = "create job "+jobname
								actionmsg = "jenkins job created"
								statusmsg = "Success"
								index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
							else
								dt+="Could not create job. Please try again"
								robot.messageRoom recipientid, dt
								setTimeout (->index.passData dt),1000
						)
			else
				dt="The jenkins job create request from "+req.body.username+" was rejected by "+req.body.approver
				robot.messageRoom recipientid, dt
				setTimeout (->index.passData dt),1000
