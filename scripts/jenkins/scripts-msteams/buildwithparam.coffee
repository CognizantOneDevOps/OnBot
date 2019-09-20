#-------------------------------------------------------------------------------
# copyright 2018 cognizant technology solutions
#   
#   licensed under the apache license, version 2.0 (the "license"); you may not
#   use this file except in compliance with the license.  you may obtain a copy
#   of the license at
#   
#     http://www.apache.org/licenses/license-2.0
#   
#   unless required by applicable law or agreed to in writing, software
#   distributed under the license is distributed on an "as is" basis, without
#   warranties or conditions of any kind, either express or implied.  see the
#   license for the specific language governing permissions and limitations under
#   the license.
#-------------------------------------------------------------------------------

#description:
# builds a given jenkins job with given parameters
# and notifies the user once build is finished
#
#configuration:
# hubot_name
# hubot_jenkins_url
# hubot_jenkins_user
# hubot_jenkins_password
# hubot_jenkins_api_token
# hubot_jenkins_version
#
#commands:
# start <jobname> build with params <paramname1>=<paramvalue1> <paramname2>=<paramvalue2>... -> start a build for
# the given jenkins job with the given parameters and notify the user once build is finished
# example~
# start job01 build with params paramnew=123 paramold=456
#
#dependencies:
# "elasticsearch": "^0.9.2"
# "request": "2.81.0"
#
#note:
# this file is for building parameterized projects only. if the given job is not parameterized then
# hubot will respond with error. for non-parameterized jobs user jenkins build <jobaname>.

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
options = {
url: '',
auth: {
'user': jenkins_user,
'pass': jenkins_api
},
method: 'post',
headers:{}};

if jenkins_version >= 2.0
	crumb.crumb (stderr, stdout) ->
		if(stdout)
			crumbvalue=stdout
			
post = (recipient, data) ->
	optons = {method: "POST", url: recipient, json: data}
	request.post optons, (error, response, body) ->
		console.log body

module.exports = (robot) ->
	robot.respond /start (.*) build with params (.+)/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			jobname=msg.match[1]
			paramstring=[]
			paramstring=msg.match[2].split(' ')
			if stdout.start_build.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.start_build.admin,podIp:process.env.MY_POD_IP,jobname:jobname,paramstring:paramstring,"callback_id":"jenkinsbuildwithparam",msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Requested to requested a build","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": 'slack user '+payload.username+' requested a build '+payload.jobname+' with following params:\n'+payload.paramstring,"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approved","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}
					#Post attachment to ms teams
					post stdout.start_build.adminid, data
					msg.send 'Your request is waiting for approval by '+stdout.start_build.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				#handles regular flow of the command without approval flow
				jobname=msg.match[1]
				paramstring=[]
				paramstring=msg.match[2].split(' ')
				url=jenkins_url+"/job/"+jobname+"/buildWithParameters?"
				i=0
				for i in [0...paramstring.length]
					if(i==paramstring.length-1)
						url=url+paramstring[i]
					else
						url=url+paramstring[i]+'&'
				options.url = url
				if jenkins_version >= 2.0
					console.log(options)
					options.headers["jenkins-crumb"]=crumbvalue
				else
					options.auth.pass = jenkins_pass
				request.post options, (error, response, body) ->
					console.log(body)
					console.log response.statusCode
					if(response.statusCode!=201)
						dt="could not initiate build. make sure the jobname and the param key(s) you have given are correct. for new params, try adding it to your jenkins project first."
						res.send(dt)
						setTimeout (->index.passdata dt),1000
					else
						dt="build initiated with given parameters\n"+jenkins_url+"/job/"+jobname
						msg.send(dt)
						setTimeout (->index.passdata dt),1000
						message = msg.match[0]
						actionmsg = "jenkins build started"
						statusmsg = "success"
						index.walldata process.env.hubot_name, message, actionmsg, statusmsg;
						if jenkins_version >= 2.0
							statuscheck.checkbuildstatus res.message.user.room,jobname,crumbvalue
						else
							statuscheck.checkbuildstatus res.message.user.room,jobname,''
	#the following code handles the approval flow of the command
	robot.router.post '/jenkinsbuildwithparam', (req, response) ->
		recipientid=req.body.userid
		dt = {"text":"","title":""}
		if(req.body.action=='Approved')
			dt.title=req.body.approver+" approved jenkins build for job "+req.body.jobname+", requested by "+req.body.username+"\n";
			jobname=req.body.jobname
			paramstring=[]
			paramstring=req.body.paramstring
			jenkins_url=process.env.HUBOT_JENKINS_URL
			jenkins_user=process.env.HUBOT_JENKINS_USER
			jenkins_pass=process.env.HUBOT_JENKINS_PASSWORD
			url=jenkins_url+"/job/"+jobname+"/buildWithParameters?"
			i=0
			for i in [0...paramstring.length]
				if(i==paramstring.length-1)
					url=url+paramstring[i]
				else
					url=url+paramstring[i]+'&'
			options.url = url
			if jenkins_version >= 2.0
				console.log(options)
				options.headers["jenkins-crumb"]=crumbvalue
			else
				options.auth.pass = jenkins_pass
			request.post options, (error, response, body) ->
				console.log(options)
				console.log response.statusCode
				if(response.statusCode!=201)
					dt.text="could not initiate build. make sure the jobname and the param key(s) you have given are correct. for new params, try adding it to your jenkins project first."
					post recipientid, dt
					setTimeout (->index.passdata dt),1000
				else
					dt.text="build initiated with given parameters\n"+jenkins_url+"/job/"+jobname
					post recipientid, dt
					setTimeout (->index.passdata dt),1000
					message = "start "+jobname+"build with params "+paramstring
					actionmsg = "jenkins build started"
					statusmsg = "success"
					index.walldata process.env.hubot_name, message, actionmsg, statusmsg;
					if jenkins_version >= 2.0
						statuscheck.checkbuildstatus recipientid,jobname,crumbvalue
					else
						statuscheck.checkbuildstatus recipientid,jobname,''
		else
			dt.title = "the build request from "+req.body.username+" was rejected by "+req.body.approver
			post recipientid, dt
			setTimeout (->index.passdata dt),1000
