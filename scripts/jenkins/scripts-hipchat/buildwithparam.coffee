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
# builds a given jenkins job with given parameters
# and notifies the user once build is finished
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
# start <jobname> build with params <paramname1>=<paramvalue1> <paramname2>=<paramvalue2>... -> start a build for
# the given jenkins job with the given parameters and notify the user once build is finished
# Example~
# start job01 build with params paramnew=123 paramold=456
#
#Dependencies:
# "elasticSearch": "^0.9.2"
# "request": "2.81.0"
#
#NOTE:
# this file is for building parameterized projects only. If the given job is not parameterized then
# hubot will respond with error. For non-parameterized jobs user jenkins build <jobaname>.

jenkins_url=process.env.HUBOT_JENKINS_URL
jenkins_user=process.env.HUBOT_JENKINS_USER
jenkins_pass=process.env.HUBOT_JENKINS_PASSWORD
jenkins_api=process.env.HUBOT_JENKINS_API_TOKEN
jenkins_version=process.env.HUBOT_JENKINS_VERSION

request = require('request')
readjson = require './readjson.js'
finaljson=" ";
index = require('./index')
statuscheck = require('./statuscheck.coffee')
generate_id = require('./mongoConnt')
crumb = require('./jenkinscrumb.js')

crumbvalue = ''
if jenkins_version >= 2.0
	crumb.crumb (stderr, stdout) ->
		if(stdout)
			crumbvalue=stdout

module.exports = (robot) ->
	robot.respond /start (.*) build with params (.+)/i, (res) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			jobname=res.match[1]
			paramString=[]
			paramString=res.match[2].split(' ')
			if stdout.start_build.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					
					payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.reply_to,podIp:process.env.MY_POD_IP,"callback_id":"jenkinsbuildwithparam",jobname:jobname,paramString:paramString}
					data='Ticket Id : '+tckid+'\n Raised By: '+res.message.user.name+'\n Command: start '+jobname+' build with params '+paramString+'\n approve or reject the request'
					robot.messageRoom(stdout.start_build.adminid, data);
					res.send 'Your request is waiting for approval by '+stdout.start_build.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				#handles regular flow of the command without approval flow
				jobname=res.match[1]
				paramString=[]
				paramString=res.match[2].split(' ')
				url=jenkins_url+"/job/"+jobname+"/buildWithParameters?"
				i=0
				for i in [0...paramString.length]
					if(i==paramString.length-1)
						url=url+paramString[i]
					else
						url=url+paramString[i]+'&'
				options = {
				auth: {
				'user': jenkins_user,
				'pass': jenkins_pass
				},
				method: 'POST',
				url: url,
				headers: {  } };
				if jenkins_version >= 2.0
					options.headers["Jenkins-Crumb"]=crumbvalue
					options.auth.pass = jenkins_api
				request.post options, (error, response, body) ->
					console.log response.statusCode
					if(response.statusCode!=201)
						dt="Could not initiate build. Make sure the jobname and the param key(s) you have given are correct. For new params, try adding it to your jenkins project first."
						res.send(dt)
						setTimeout (->index.passData dt),1000
					else
						dt="Build initiated with given parameters\n"+jenkins_url+"/job/"+jobname
						res.send(dt)
						setTimeout (->index.passData dt),1000
						message = res.match[0]
						actionmsg = "jenkins build started"
						statusmsg = "Success"
						index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
						if jenkins_version >= 2.0
							statuscheck.checkbuildstatus res.message.user.reply_to,jobname,crumbvalue
						else
							statuscheck.checkbuildstatus res.message.user.reply_to,jobname,''
	#the following code handles the approval flow of the command
	robot.router.post '/jenkinsbuildwithparam', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved jenkins build for job "+req.body.jobname+", requested by "+req.body.username+"\n"
			jobname=req.body.jobname
			paramString=[]
			paramString=req.body.paramString
			url=jenkins_url+"/job/"+jobname+"/buildWithParameters?"
			i=0
			for i in [0...paramString.length]
				if(i==paramString.length-1)
					url=url+paramString[i]
				else
					url=url+paramString[i]+'&'
			options = {
			auth: {
			'user': jenkins_user,
			'pass': jenkins_pass
			},
			method: 'POST',
			url: url,
			headers: {  } };
			if jenkins_version >= 2.0
				options.headers["Jenkins-Crumb"]=crumbvalue
				options.auth.pass = jenkins_api
			request.post options, (error, response, body) ->
				console.log response.statusCode
				if(response.statusCode!=201)
					dt+="Could not initiate build. Make sure the jobname and the param key(s) you have given are correct. For new params, try adding it to your jenkins project first."
					robot.messageRoom recipientid, dt
					setTimeout (->index.passData dt),1000
				else
					dt+="Build initiated with given parameters\n"+jenkins_url+"/job/"+jobname
					robot.messageRoom recipientid, dt
					setTimeout (->index.passData dt),1000
					message = "start "+jobname+" build with params "+paramString
					actionmsg = "jenkins build started"
					statusmsg = "Success"
					index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
					if jenkins_version >= 2.0
						statuscheck.checkbuildstatus recipientid,jobname,crumbvalue
					else
						statuscheck.checkbuildstatus recipientid,jobname,''
		else
			dt="The build request from "+req.body.username+" was rejected by "+req.body.approver
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
