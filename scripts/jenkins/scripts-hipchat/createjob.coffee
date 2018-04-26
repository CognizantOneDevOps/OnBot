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
# creates a jenkins job with the configuration in the given config.xml
# config.xml has to be created by user, ensure it is errorfree and adheres to jenkins standards for a config.xml fileData
#
#Configuration:
# HUBOT_NAME
# HUBOT_JENKINS_URL
# HUBOT_JENKINS_USER
# HUBOT_JENKINS_PASSWORD
#
#COMMANDS:
# create job <jobname> with <full_config_name_with_extension> -> creates a jenkins job with the given config.xml file
#
#Description:
# "elasticSearch": "^0.9.2"
# "request": "2.81.0"

request = require('request')
fs=require('fs')
index = require('./index')
readjson = require './readjson.js'
finaljson=" ";
generate_id = require('./mongoConnt')

module.exports = (robot) ->
	robot.respond /create job (.*) with (.*)/i, (res) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			#reading workflow.json
			finaljson=stdout;
			jobname=res.match[1]
			if stdout.create_job.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.reply_to,podIp:process.env.MY_POD_IP,"callback_id":"jenkinscreate",jobname:jobname,userxml:res.match[2]}
					data='Ticket Id : '+tckid+'\n Raised By: '+res.message.user.name+'\n Command: create job '+jobname+' with '+payload.userxml+'\n approve or reject the request'
					robot.messageRoom(stdout.create_job.adminid, data);
					res.send 'Your request is waiting for approval by '+stdout.create_job.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				#handles regular flow of the command without approval flow
				jobname=res.match[1]
				user_xml=res.match[2]
				jenkins_url=process.env.HUBOT_JENKINS_URL
				jenkins_user=process.env.HUBOT_JENKINS_USER
				jenkins_pass=process.env.HUBOT_JENKINS_PASSWORD
				url=jenkins_url+"/createItem?name="+jobname+""
				fs.readFile './scripts/'+user_xml, 'utf8', (err, fileData) ->
					if(err)
						dt="Error in reading XML: " +err
						res.send(dt)
						setTimeout (->index.passData dt),1000
					else
						options = {
						url: url,
						auth: {
						'user': jenkins_user,
						'pass': jenkins_pass
						},
						method: 'POST',
						headers: {"Content-Type":"text/xml"},
						body: fileData};
						request.post(options, (error, response, body) ->
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
			jenkins_url=process.env.HUBOT_JENKINS_URL
			jenkins_user=process.env.HUBOT_JENKINS_USER
			jenkins_pass=process.env.HUBOT_JENKINS_PASSWORD
			url=jenkins_url+"/createItem?name="+jobname+""
			fs.readFile user_xml, 'utf8', (err, fileData) ->
				if(err)
					dt+="Error in reading XML: " +err
					robot.messageRoom recipientid, dt
					setTimeout (->index.passData dt),1000
				else
					options = {
					url: url,
					auth: {
					'user': jenkins_user,
					'pass': jenkins_pass
					},
					method: 'POST',
					headers: {"Content-Type":"text/xml"},
					body: fileData};
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
