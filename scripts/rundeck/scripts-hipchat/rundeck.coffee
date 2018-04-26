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
password = process.env.RUNDECK_PASSWORD
botname = process.env.HUBOT_NAME
rundeckapi = require('./rundeckapi.js');
getjson = require './getjson.js'
generate_id = require('./mongoConnt')
module.exports = (robot) ->
	robot.respond /list jobs (.*)/i, (msg) ->
		projname = msg.match[1]
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.listjob.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,podIp:process.env.MY_POD_IP,"callback_id":"rundeck_list_job","projname":projname}
					message='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: listjob '+projname+'\n approve or reject the request'
					robot.messageRoom(stdout.listjob.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.listjob.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert

			#Normal action without workflow flag
			else
				rundeckapi.listjob rundeck_url, username, password, rundeck_token, projname, (error, stdout, stderr) ->
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
	#Listening the post url  
	robot.router.post '/rundeck_list_job', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						rundeckapi.listjob rundeck_url, username, password, rundeck_token, data.projname, (error, stdout, stderr) ->
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
			
	robot.respond /help/i, (msg) ->
		msg.send 'list projects \n list jobs <project name>\n create project <filename> \n get config <projectname> \n run job <jobid> \n delete job<jobid> \n delete project <projectname> \n get history <projectname>'
	robot.respond /list projects/i, (msg) ->
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.listproject.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,podIp:process.env.MY_POD_IP,"callback_id":"rundeck_list_project"}
					message='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: listproject \n approve or reject the request'
					robot.messageRoom(stdout.listproject.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.listproject.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert

			#Normal action without workflow flag
			else
				rundeckapi.listproj rundeck_url, username, password, rundeck_token, (error, stdout, stderr) ->
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
	#Listening the post url
	robot.router.post '/rundeck_list_project', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						rundeckapi.listproj rundeck_url, username, password, rundeck_token, (error, stdout, stderr) ->
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
			
	robot.respond /create project (.*)/i, (msg) ->
		filename = msg.match[1]
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.createproject.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,podIp:process.env.MY_POD_IP,"callback_id":"rundeck_create_project","filename":filename}
					message='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: create project \n approve or reject the request'
					robot.messageRoom(stdout.createproject.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.createproject.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert

			#Normal action without workflow flag
			else
				rundeckapi.createproject rundeck_url, username, password, rundeck_token, filename, (error, stdout, stderr) ->
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
	#Listening the post url
	robot.router.post '/rundeck_create_project', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						rundeckapi.createproject rundeck_url, username, password, rundeck_token, data.filename, (error, stdout, stderr) ->
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
			
	robot.respond /get config (.*)/i, (msg) ->
		projectname = msg.match[1]
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.getconfig.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,podIp:process.env.MY_POD_IP,"callback_id":"rundeck_get_config","projectname":projectname}
					message='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: get config '+projectname+'\n approve or reject the request'
					robot.messageRoom(stdout.getconfig.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.getconfig.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert

			#Normal action without workflow flag
			else
				rundeckapi.projconfig rundeck_url, username, password, rundeck_token, projectname, (error, stdout, stderr) ->
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
	#Listening the post url
	robot.router.post '/rundeck_get_config', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						rundeckapi.projconfig rundeck_url, username, password, rundeck_token, data.projectname, (error, stdout, stderr) ->
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
			
	robot.respond /run job (.*)/i, (msg) ->
		jobid = msg.match[1]
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.runjob.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,podIp:process.env.MY_POD_IP,"callback_id":"rundeck_run_job","jobid":jobid}
					message='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: run job '+jobid+'\n approve or reject the request'
					robot.messageRoom(stdout.runjob.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.runjob.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
				
			#Normal action without workflow flag
			else
				rundeckapi.runjob rundeck_url, username, password, rundeck_token, jobid, (error, stdout, stderr) ->
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
							rundeckapi.checkstatus rundeck_url, username, password, rundeck_token, execid[1], (error, stdout, stderr) ->
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
	#Listening the post url
	robot.router.post '/rundeck_run_job', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						rundeckapi.runjob rundeck_url, username, password, rundeck_token, data.jobid, (error, stdout, stderr) ->
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
									rundeckapi.checkstatus rundeck_url, username, password, rundeck_token, execid[1], (error, stdout, stderr) ->
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
			
	robot.respond /delete job (.*)/i, (msg) ->
		jobid = msg.match[1]
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.deletejob.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,podIp:process.env.MY_POD_IP,"callback_id":"rundeck_delete_job","jobid":jobid}
					message='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: delete job '+jobid+'\n approve or reject the request'
					robot.messageRoom(stdout.deletejob.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.deletejob.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
				
			#Normal action without workflow flag
			else
				rundeckapi.deletejob rundeck_url, username, password, rundeck_token, jobid, (error, stdout, stderr) ->
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
	#Listening the post url
	robot.router.post '/rundeck_delete_job', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						rundeckapi.deletejob rundeck_url, username, password, rundeck_token, data.jobid, (error, stdout, stderr) ->
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
			
	robot.respond /delete project (.*)/i, (msg) ->
		projectname = msg.match[1]
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.deleteproject.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,podIp:process.env.MY_POD_IP,"callback_id":"rundeck_delete_project","projectname":projectname}
					message='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: delete project '+projectname+'\n approve or reject the request'
					robot.messageRoom(stdout.deleteproject.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.deleteproject.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
				
			#Normal action without workflow flag
			else
				rundeckapi.deleteproj rundeck_url, username, password, rundeck_token, projectname, (error, stdout, stderr) ->
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
	#Listening the post url
	robot.router.post '/rundeck_delete_project', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						rundeckapi.deleteproj rundeck_url, username, password, rundeck_token, data.projectname, (error, stdout, stderr) ->
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
			
	robot.respond /get history (.*)/i, (msg) ->
		projectname = msg.match[1]
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.projecthistory.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,podIp:process.env.MY_POD_IP,"callback_id":"rundeck_project_history","projectname":projectname}
					message='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: get project history '+projectname+'\n approve or reject the request'
					robot.messageRoom(stdout.projecthistory.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.projecthistory.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
				
			#Normal action without workflow flag
			else
				rundeckapi.exechistory rundeck_url, username, password, rundeck_token, projectname, (error, stdout, stderr) ->
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
	#Listening the post url
	robot.router.post '/rundeck_project_history', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						rundeckapi.exechistory rundeck_url, username, password, rundeck_token, data.projectname, (error, stdout, stderr) ->
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
	
