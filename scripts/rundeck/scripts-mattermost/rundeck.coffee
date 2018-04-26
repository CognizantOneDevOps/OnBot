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

#Bot commands
#
#list projects -> list projects in rundeck
#list jobs <project name> -> list jobs of provided project
#create project <filename>  -> create a new project in rundeck based on the <config file>
#get config <projectname> -> get configuration of provided project
#run job <jobid> -> run the job by <jobid>
#delete job<jobid> -> delete job by <job id>
#delete project <projectname> -> delete project by <projectname>
#get history <projectname> -> get history of provided project
#
#Set env:
#
#HUBOT_NAME
#RUNDECK_URL	
#RUNDECK_TOKEN	
#RUNDECK_USERNAME
#RUNDECK_PASSWORD
eindex = require('./index')

rundeck_url = process.env.RUNDECK_URL
rundeck_token = process.env.RUNDECK_TOKEN
username = process.env.RUNDECK_USERNAME
pawwsord = process.env.RUNDECK_PASSWORD
botname = process.env.HUBOT_NAME
rundeckapi = require('./rundeckapi.js');
#list = require('./listuserchannel.js');
getjson = require './getjson.js'
generate_id = require('./mongoConnt')
request = require('request')
module.exports = (robot) ->
	cmdlistjob = new RegExp('@' + process.env.HUBOT_NAME + ' list jobs (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdlistjob
		(msg) ->
			projname = msg.match[1]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.listjob.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.listjob.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,repoid:repoid,callback_id: 'rundeck_list_job',tckid:tckid};
						data = {"channel": stdout.listjob.admin,"text":"Approve Request for listing rundeck jobs","message":"Request to list rundeck jobs with ID: "+payload.repoid,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'rundeck_list_job',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '+stdout.listjob.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
					
			#Normal action without workflow flag
				else
					rundeckapi.listjob rundeck_url, username, pawwsord, rundeck_token, projname, (error, stdout, stderr) ->
						if error
							setTimeout (->eindex.passData error),1000
							console.log(error)
							msg.send "Error occured while getting list of jobs";
						if stderr
							setTimeout (->eindex.passData stderr),1000
							console.log(stderr)
							msg.send stderr;
						if stdout
							setTimeout (->eindex.passData stdout),1000
							console.log(stdout);
							msg.send stdout;
	)
	#Listening the post url  
	robot.router.post '/rundeck_list_job', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approve'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						rundeckapi.listjob rundeck_url, username, pawwsord, rundeck_token, data.projname, (error, stdout, stderr) ->
							if error
								setTimeout (->eindex.passData error),1000
								console.log(error)
								robot.messageRoom data.userid, "Error occured while getting list of jobs";
							if stderr
								setTimeout (->eindex.passData stderr),1000
								console.log(stderr)
								robot.messageRoom data.userid, stderr;
							if stdout
								setTimeout (->eindex.passData stdout),1000
								console.log(stdout);
								robot.messageRoom data.userid, stdout;
					#Action flow after reject
					else
						robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
					response.send 'success http call'
	cmdhelp = new RegExp('@' + process.env.HUBOT_NAME + ' help')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdhelp
		(msg) ->
			msg.send 'list projects \n list jobs <project name>\n create project <filename> \n get config <projectname> \n run job <jobid> \n delete job<jobid> \n delete project <projectname> \n get history <projectname>'
	)
	cmdlistproj = new RegExp('@' + process.env.HUBOT_NAME + ' list projects')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdlistproj
		(msg) ->
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.listproject.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.listproject.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,repoid:repoid,callback_id: 'rundeck_list_project',tckid:tckid};
						data = {"channel": stdout.listproject.admin,"text":"Approve Request for listing rundeck projects","message":"Request to list rundeck projects with ID: "+payload.repoid,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'rundeck_list_project',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '+stdout.listproject.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert

				#Normal action without workflow flag
				else
					rundeckapi.listproj rundeck_url, username, pawwsord, rundeck_token, (error, stdout, stderr) ->
						if error
							setTimeout (->eindex.passData error),1000
							console.log(error)
							msg.send "Error occured while getting list of projects";
						if stderr
							setTimeout (->eindex.passData stderr),1000
							console.log(stderr)
							msg.send stderr;
						if stdout
							setTimeout (->eindex.passData stdout),1000
							console.log(stdout);
							msg.send stdout;
	)
	#Listening the post url
	robot.router.post '/rundeck_list_project', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approve'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						rundeckapi.listproj rundeck_url, username, pawwsord, rundeck_token, (error, stdout, stderr) ->
							if error
								setTimeout (->eindex.passData error),1000
								console.log(error)
								robot.messageRoom data.userid, "Error occured while getting list of projects";
							if stderr
								setTimeout (->eindex.passData stderr),1000
								console.log(stderr)
								robot.messageRoom data.userid, stderr;
							if stdout
								setTimeout (->eindex.passData stdout),1000
								console.log(stdout);
								robot.messageRoom data.userid, stdout;
					#Action flow after reject
					else
						robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
					response.send 'success http call'
	cmdcreateproj = new RegExp('@' + process.env.HUBOT_NAME + ' create project (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreateproj
		(msg) ->
			filename = msg.match[1]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.createproject.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.createproject.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,filename:filename,callback_id: 'rundeck_create_project',tckid:tckid};
						data = {"channel": stdout.createproject.admin,"text":"Request from "+payload.username+" for creating rundeck project","message":"Request to create rundeck project with file: "+payload.filename,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'rundeck_create_project',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '+stdout.createproject.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert

				#Normal action without workflow flag
				else
					rundeckapi.createproject rundeck_url, username, pawwsord, rundeck_token, filename, (error, stdout, stderr) ->
						if error
							setTimeout (->eindex.passData error),1000
							console.log(error)
							msg.send "Error occured while creating project";
						if stderr
							setTimeout (->eindex.passData stderr),1000
							console.log(stderr)
							msg.send stderr;
						if stdout
							setTimeout (->eindex.passData stdout),1000
							message = msg.match[0]
							actionmsg = "rundeck project created"
							statusmsg = "success"
							eindex.wallData botname, message, actionmsg, statusmsg;
							console.log(stdout);
							msg.send stdout;
	)
	#Listening the post url
	robot.router.post '/rundeck_create_project', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approve'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						rundeckapi.createproject rundeck_url, username, pawwsord, rundeck_token, data.filename, (error, stdout, stderr) ->
							if error
								setTimeout (->eindex.passData error),1000
								console.log(error)
								robot.messageRoom data.userid, "Error occured while creating project";
							if stderr
								setTimeout (->eindex.passData stderr),1000
								console.log(stderr)
								robot.messageRoom data.userid, stderr;
							if stdout
								setTimeout (->eindex.passData stdout),1000
								message = "create project "+data.filename
								actionmsg = "rundeck project created"
								statusmsg = "success"
								eindex.wallData botname, message, actionmsg, statusmsg;
								console.log(stdout);
								robot.messageRoom data.userid, stdout;
					#Action flow after reject
					else
						robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
					response.send 'success http call'
	cmdgetconfig = new RegExp('@' + process.env.HUBOT_NAME + ' get config (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdgetconfig
		(msg) ->
			projectname = msg.match[1]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.getconfig.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.getconfig.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,repoid:repoid,callback_id: 'rundeck_get_config',tckid:tckid};
						data = {"channel": stdout.getconfig.admin,"text":"Approve Request for deleting rundeck repo","message":"Request to delete rundeck repo with ID: "+payload.repoid,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'rundeck_get_config',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '+stdout.getconfig.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert

			#Normal action without workflow flag
				else
					rundeckapi.projconfig rundeck_url, username, pawwsord, rundeck_token, projectname, (error, stdout, stderr) ->
						if error
							setTimeout (->eindex.passData error),1000
							console.log(error)
							msg.send "Error occured while getting project configuration";
						if stderr
							setTimeout (->eindex.passData stderr),1000
							console.log(stderr)
							msg.send stderr;
						if stdout
							setTimeout (->eindex.passData stdout),1000
							console.log(stdout)
							config=JSON.stringify(stdout)
							msg.send config;
	)
	#Listening the post url
	robot.router.post '/rundeck_get_config', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approve'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						rundeckapi.projconfig rundeck_url, username, pawwsord, rundeck_token, data.projectname, (error, stdout, stderr) ->
							if error
								setTimeout (->eindex.passData error),1000
								console.log(error)
								robot.messageRoom data.userid, "Error occured while getting project configuration";
							if stderr
								setTimeout (->eindex.passData stderr),1000
								console.log(stderr)
								robot.messageRoom data.userid, stderr;
							if stdout
								setTimeout (->eindex.passData stdout),1000
								console.log(stdout)
								config=JSON.stringify(stdout)
								robot.messageRoom data.userid, config;		
					#Action flow after reject
					else
						robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
					response.send 'success http call'
	cmdrunjob = new RegExp('@' + process.env.HUBOT_NAME + ' run job (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdrunjob
		(msg) ->
			jobid = msg.match[1]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.runjob.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.runjob.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,jobid:jobid,callback_id: 'rundeck_run_job',tckid:tckid};
						data = {"channel": stdout.runjob.admin,"text":"Request from "+payload.username+" for running job","message":"Request to run rundeck job with ID: "+payload.jobid,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'rundeck_run_job',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '+stdout.runjob.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				
				#Normal action without workflow flag
				else
					rundeckapi.runjob rundeck_url, username, pawwsord, rundeck_token, jobid, (error, stdout, stderr) ->
						if error
							setTimeout (->eindex.passData error),1000
							console.log(error)
							msg.send "Error occured while running the job";
						if stderr
							setTimeout (->eindex.passData error),1000
							console.log(stderr)
							msg.send stderr;
				
							
						if stdout
							setTimeout (->eindex.passData stdout),1000
							msg.send stdout;
							execid=[]
							execid=stdout.split(" ");
							checkstatus = () ->
								rundeckapi.checkstatus rundeck_url, username, pawwsord, rundeck_token, execid[1], (error, stdout, stderr) ->
									if error
										setTimeout (->eindex.passData error),1000
										console.log(error)
										msg.send "some occured while running your job ";
										clearTimeout intervalId
									if stderr
										setTimeout (->eindex.passData stderr),1000
										console.log(stderr)
										msg.send stderr;
										clearTimeout intervalId
									if stdout
										status=[]
										status=stdout.split(" ");
										if status[0]=="succeeded" || status[0]=="failed"
											setTimeout (->eindex.passData stdout),1000
											message = msg.match[0]
											actionmsg = "rundeck job started"
											statusmsg = "success"
											eindex.wallData botname, message, actionmsg, statusmsg;
											console.log(stdout)
											msg.send stdout;
											clearTimeout intervalId
							intervalId = setInterval(checkstatus, 5000);#1000 = 1 sec
	)
	#Listening the post url
	robot.router.post '/rundeck_run_job', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approve'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						rundeckapi.runjob rundeck_url, username, pawwsord, rundeck_token, data.jobid, (error, stdout, stderr) ->
							if error
								setTimeout (->eindex.passData error),1000
								console.log(error)
								robot.messageRoom data.userid, "Error occured while running the job";
							if stderr
								setTimeout (->eindex.passData error),1000
								console.log(stderr)
								robot.messageRoom data.userid, stderr;
				
							
							if stdout
								setTimeout (->eindex.passData stdout),1000
								robot.messageRoom data.userid, stdout;
								execid=[]
								execid=stdout.split(" ");
								checkstatus = () ->
									rundeckapi.checkstatus rundeck_url, username, pawwsord, rundeck_token, execid[1], (error, stdout, stderr) ->
										if error
											setTimeout (->eindex.passData error),1000
											console.log(error)
											robot.messageRoom data.userid, "some occured while running your job ";
											clearTimeout intervalId
										if stderr
											setTimeout (->eindex.passData stderr),1000
											console.log(stderr)
											robot.messageRoom data.userid, stderr;
											clearTimeout intervalId
										if stdout
											status=[]
											status=stdout.split(" ");
											if status[0]=="succeeded" || status[0]=="failed"
												setTimeout (->eindex.passData stdout),1000
												message = "run job "+data.jobid
												actionmsg = "rundeck job started"
												statusmsg = "success"
												eindex.wallData botname, message, actionmsg, statusmsg;
												console.log(stdout)
												robot.messageRoom data.userid, stdout;
												clearTimeout intervalId
								intervalId = setInterval(checkstatus, 5000);#1000 = 1 sec
					else
						robot.messageRoom data.userid, 'your request is rejected by'+data.approver;
					response.send 'success http call'
	cmddeletejob = new RegExp('@' + process.env.HUBOT_NAME + ' delete job (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddeletejob
		(msg) ->
			jobid = msg.match[1]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.deletejob.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.deletejob.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,jobid:jobid,callback_id: 'rundeck_delete_job',tckid:tckid};
						data = {"channel": stdout.deletejob.admin,"text":"Request from "+payload.username+" for deleting rundeck repo","message":"Request to delete rundeck job with ID: "+payload.jobid,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'rundeck_delete_job',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '+stdout.deletejob.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				
				#Normal action without workflow flag
				else
					rundeckapi.deletejob rundeck_url, username, pawwsord, rundeck_token, jobid, (error, stdout, stderr) ->
						if error
							setTimeout (->eindex.passData error),1000
							console.log(error)
							msg.send "Error occured while deleting job";
						if stderr
							setTimeout (->eindex.passData stderr),1000
							console.log(stderr)
							msg.send stderr;
						if stdout
							setTimeout (->eindex.passData stdout),1000
							message = msg.match[0]
							actionmsg = "rundeck job deleted"
							statusmsg = "success"
							eindex.wallData botname, message, actionmsg, statusmsg;
							console.log(stdout)
							msg.send stdout;
	)
	#Listening the post url
	robot.router.post '/rundeck_delete_job', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approve'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						rundeckapi.deletejob rundeck_url, username, pawwsord, rundeck_token, data.jobid, (error, stdout, stderr) ->
							if error
								setTimeout (->eindex.passData error),1000
								console.log(error)
								robot.messageRoom data.userid, "Error occured while deleting job";
							if stderr
								setTimeout (->eindex.passData stderr),1000
								console.log(stderr)
								robot.messageRoom data.userid, stderr;
							if stdout
								setTimeout (->eindex.passData stdout),1000
								message = "delete job "+data.jobid
								actionmsg = "rundeck job deleted"
								statusmsg = "success"
								eindex.wallData botname, message, actionmsg, statusmsg;
								console.log(stdout)
								robot.messageRoom data.userid, stdout;
					#Action flow after reject
					else
						robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
					response.send 'success http call'
	cmddeleteproj = new RegExp('@' + process.env.HUBOT_NAME + ' delete project (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddeleteproj
		(msg) ->
			projectname = msg.match[1]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.deleteproject.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.deleteproject.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,repoid:repoid,callback_id: 'rundeck_delete_project',tckid:tckid};
						data = {"channel": stdout.deleteproject.admin,"text":"Approve Request for deleting rundeck repo","message":"Request to delete rundeck repo with ID: "+payload.repoid,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'rundeck_delete_project',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '+stdout.deleteproject.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				
				#Normal action without workflow flag
				else
					rundeckapi.deleteproj rundeck_url, username, pawwsord, rundeck_token, projectname, (error, stdout, stderr) ->
						if error
							setTimeout (->eindex.passData error),1000
							console.log(error)
							msg.send "Error occured while deleting project";
						if stderr
							setTimeout (->eindex.passData stderr),1000
							console.log(stderr)
							msg.send stderr;
						if stdout
							setTimeout (->eindex.passData stdout),1000
							message = msg.match[0]
							actionmsg = "rundeck project deleted"
							statusmsg = "success"
							eindex.wallData botname, message, actionmsg, statusmsg;
							console.log(stdout)
							msg.send stdout;
	)
	#Listening the post url
	robot.router.post '/rundeck_delete_project', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approve'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						rundeckapi.deleteproj rundeck_url, username, pawwsord, rundeck_token, data.projectname, (error, stdout, stderr) ->
							if error
								setTimeout (->eindex.passData error),1000
								console.log(error)
								robot.messageRoom data.userid, "Error occured while deleting project";
							if stderr
								setTimeout (->eindex.passData stderr),1000
								console.log(stderr)
								robot.messageRoom data.userid, stderr;
							if stdout
								setTimeout (->eindex.passData stdout),1000
								message = "delete project "+data.projectname
								actionmsg = "rundeck project deleted"
								statusmsg = "success"
								eindex.wallData botname, message, actionmsg, statusmsg;
								console.log(stdout)
								robot.messageRoom data.userid, stdout;
					#Action flow after reject
					else
						robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
					response.send 'success http call'
	cmdgethist = new RegExp('@' + process.env.HUBOT_NAME + ' get history (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdgethist
		(msg) ->
			projectname = msg.match[1]
			getjson.getworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
				if(stdout.projecthistory.workflowflag)
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.projecthistory.admin,podIp:process.env.MY_POD_IP,message:msg.message.text,repoid:repoid,callback_id: 'rundeck_project_history',tckid:tckid};
						data = {"channel": stdout.projecthistory.admin,"text":"Approve Request for deleting rundeck repo","message":"Request to delete rundeck repo with ID: "+payload.repoid,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'rundeck_project_history',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval from '+stdout.projecthistory.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				
				#Normal action without workflow flag
				else
					rundeckapi.exechistory rundeck_url, username, pawwsord, rundeck_token, projectname, (error, stdout, stderr) ->
						if error
							setTimeout (->eindex.passData error),1000
							console.log(error)
							msg.send "Error occured while getting history";
						if stderr
							setTimeout (->eindex.passData stderr),1000
							console.log(stderr)
							msg.send stderr;
						if stdout
							setTimeout (->eindex.passData stdout),1000
							msg.send stdout;
	)
	#Listening the post url
	robot.router.post '/rundeck_project_history', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						rundeckapi.exechistory rundeck_url, username, pawwsord, rundeck_token, data.projectname, (error, stdout, stderr) ->
							if error
								setTimeout (->eindex.passData error),1000
								console.log(error)
								robot.messageRoom data.userid, "Error occured while getting history";
							if stderr
								setTimeout (->eindex.passData stderr),1000
								console.log(stderr)
								robot.messageRoom data.userid, stderr;
							if stdout
								setTimeout (->eindex.passData stdout),1000
								robot.messageRoom data.userid, stdout;
					#Action flow after reject
					else
						robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
					response.send 'success http call'
			
