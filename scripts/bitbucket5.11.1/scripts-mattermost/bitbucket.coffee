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

request =require('request')
fs = require('fs')
eindex = require('./index')
listproject = require('./listproject.js')
listrepo = require('./listrepo.js')
createuser = require('./createuser.js')
deleteuser = require('./deleteuser.js')
createproj = require('./createproject.js')
deleteproj = require('./deleteproject.js')
createrepo = require('./createrepo.js')
deleterepo = require('./deleterepo.js')
createbranch = require('./createbranch.js')
deletebranch = require('./deletebranch.js')
projpermission = require('./projpermission.js')
userpermission = require('./userpermission.js')
readjson = require ('./readjson.js');
generate_id = require('./mongoConnt');

module.exports = (robot) ->
	cmdhelp = new RegExp('@' + process.env.HUBOT_NAME + ' help')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdhelp
		(res) ->
			res.send "list repo-->list repo <prjkey>\nlist projects-->list projects\ncreate user-->create user <username> <pwd> <email>\nprovide permission to user for project-->project permission <permission> to <user> for <prjkey>(possible permissions::PROJECT_READ,PROJECT_WRITE,PROJECT_ADMIN)\ngrant user permission--><user> premission <permission>(possible permissions::LICENSED_USER,PROJECT_CREATE,ADMIN,SYS_ADMIN)\ndelete user-->delete user <username>\ncreate project-->create project <prjkey> with  <prjname> desc <prjdecsc>\ndelete project-->delete project <prj key>\ncreate repo-->create repo <prjkey> <reponame>\ndelete repo-->delete repo <reposlug> in <prjkey>\ncreate branch-->create branch <branchname> in <prjkey> repo <reposlug> from <frombranch>\ndelete branch--> delete branch <branchname> from <prjkey> in <reposlug>"
	) 

	cmdlistrepo = new RegExp('@' + process.env.HUBOT_NAME + ' list repo (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdlistrepo
		(res) ->
	
			projectkey=res.match[1]
			listrepo.listrepo process.env.BITBUCKET_URL, process.env.USERNAME, process.env.PASSWORD,projectkey, (error,stdout,stderr) ->
				if(stdout)
					console.log(stdout)
					res.send stdout 
					setTimeout (->eindex.passData stdout),1000
					
				if(stderr)
					console.log(stderr)
					res.send stderr
					setTimeout (->eindex.passData stderr),1000
				
				if(error)
					console.log(error)
					res.send error
					setTimeout (->eindex.passData error),1000
	)

	cmdlistproj = new RegExp('@' + process.env.HUBOT_NAME + ' list projects')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdlistproj
		(res) ->
	
			listproject.listproject process.env.BITBUCKET_URL, process.env.USERNAME, process.env.PASSWORD, (error,stdout,stderr) ->
				if(stdout)
					console.log(stdout)
					res.send stdout
					setTimeout (->eindex.passData stdout),1000
				
				if(stderr)
					console.log(stderr)
					res.send stderr
					setTimeout (->eindex.passData stderr),1000
				
				if(error)
					console.log(error)
					res.send error
					setTimeout (->eindex.passData error),1000
	)

	cmdcreateuser = new RegExp('@' + process.env.HUBOT_NAME + ' create user (.*) (.*) (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreateuser
		(res) ->
		
			user=res.match[1]
			userpassword=res.match[2]
			emailaddress=res.match[3]
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				#Action Flow with workflow flag
				if stdout.bitbucketcreateuser.workflowflag == true
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"bitbucketcreateuser",user:user,userpassword:userpassword,emailaddress:emailaddress}
						data = {"channel": stdout.bitbucketcreateuser.admin,"text":"Request from "+payload.username+" to create bitbucket user "+user,"message":"Request from "+payload.username+" to create bitbucket user "+user,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'bitbucketcreateuser',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							res.send 'Your request is waiting for approval from '+stdout.bitbucketcreateuser.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Casual workflow
				else
					createuser.createuser process.env.BITBUCKET_URL, process.env.USERNAME, process.env.PASSWORD, user, userpassword, emailaddress, (error,stdout,stderr) ->
						if(stdout)
							console.log(stdout)
							res.send stdout
							setTimeout (->eindex.passData stdout),1000
							message = 'bitbucket user created ';
							actionmsg = 'bitbucket user created ';
							statusmsg = 'Success';
							eindex.wallData botname, message, actionmsg, statusmsg;
						
						if(stderr)
							console.log(stderr)
							res.send stderr
							setTimeout (->eindex.passData stderr),1000
						
						if(error)
							console.log(error)
							res.send error
							setTimeout (->eindex.passData error),1000
	)
						
	robot.router.post '/bitbucketcreateuser', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' for the creating of user';
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			user = request.body.user;
			userpassword = request.body.userpassword;
			emailaddress = request.body.emailaddress;
			# Call from create_project file for project creation 
			createuser.createuser process.env.BITBUCKET_URL, process.env.USERNAME, process.env.PASSWORD, user, userpassword, emailaddress, (error,stdout,stderr) ->
				if(stdout)
					console.log(stdout)
					res.send stdout
					setTimeout (->eindex.passData stdout),1000
					message = 'bitbucket user created ';
					actionmsg = 'bitbucket user created ';
					statusmsg = 'Success';
					eindex.wallData botname, message, actionmsg, statusmsg;
				
				if(stderr)
					console.log(stderr)
					res.send stderr
					setTimeout (->eindex.passData stderr),1000
				
				if(error)
					console.log(error)
					res.send error
					setTimeout (->eindex.passData error),1000
		else
			dt="Create bitbucket user request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to create bitbucket user.';

	cmddeleteuser = new RegExp('@' + process.env.HUBOT_NAME + ' delete user (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddeleteuser
		(res) ->
		
			user=res.match[1]
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				#Action Flow with workflow flag
				if stdout.bitbucketdeleteuser.workflowflag == true
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"bitbucketdeleteuser",user:user}
						data = {"channel": stdout.bitbucketdeleteuser.admin,"text":"Request from "+payload.username+" to delete bitbucket user "+user,"message":"Request from "+payload.username+" to delete bitbucket user "+user,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'bitbucketdeleteuser',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							res.send 'Your request is waiting for approval from '+stdout.bitbucketdeleteuser.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Casual workflow
				else
					deleteuser.deleteuser process.env.BITBUCKET_URL, process.env.USERNAME, process.env.PASSWORD, user, (error,stdout,stderr) ->
						if(stdout)
							console.log(stdout)
							res.send stdout
							setTimeout (->eindex.passData stdout),1000
							message = 'bitbucket user deleted ';
							actionmsg = 'bitbucket user deleted ';
							statusmsg = 'Success';
							eindex.wallData botname, message, actionmsg, statusmsg;
						
						if(stderr)
							console.log(stderr)
							res.send stderr
							setTimeout (->eindex.passData stderr),1000
						
						if(error)
							console.log(error)
							res.send error
							setTimeout (->eindex.passData error),1000
	)

	robot.router.post '/bitbucketdeleteuser', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' for the deleting of user';
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			user = request.body.user;
			# Call from create_project file for project creation 
			deleteuser.deleteuser process.env.BITBUCKET_URL, process.env.USERNAME, process.env.PASSWORD, user, (error,stdout,stderr) ->
				if(stdout)
					console.log(stdout)
					res.send stdout
					setTimeout (->eindex.passData stdout),1000
					message = 'bitbucket user deleted ';
					actionmsg = 'bitbucket user deleted ';
					statusmsg = 'Success';
					eindex.wallData botname, message, actionmsg, statusmsg;
				
				if(stderr)
					console.log(stderr)
					res.send stderr
					setTimeout (->eindex.passData stderr),1000
				
				if(error)
					console.log(error)
					res.send error
					setTimeout (->eindex.passData error),1000
		else
			dt="Delete bitbucket user request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to delete bitbucket user.';
				
	cmdcreateproj = new RegExp('@' + process.env.HUBOT_NAME + ' create project (.*) with (.*) desc (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreateproj
		(res) -> 
		
			projectkey=res.match[1]
			projectname=res.match[2]
			description=res.match[3]
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				#Action Flow with workflow flag
				if stdout.bitbucketcreateproj.workflowflag == true
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"bitbucketcreateproj",projectkey:projectkey,projectname:projectname,description:description}
						data = {"channel": stdout.bitbucketcreateproj.admin,"text":"Request from "+payload.username+" to create bitbucket project "+projectname,"message":"Request from "+payload.username+" to create bitbucket project "+projectname,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'bitbucketcreateproj',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							res.send 'Your request is waiting for approval from '+stdout.bitbucketcreateproj.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Casual workflow
				else
					createproj.createproj process.env.BITBUCKET_URL, process.env.USERNAME, process.env.PASSWORD, projectkey, projectname, description, (error,stdout,stderr) ->
						if(stdout)
							console.log(stdout)
							res.send stdout
							setTimeout (->eindex.passData stdout),1000
							message = 'bitbucket project created ';
							actionmsg = 'bitbucket project created ';
							statusmsg = 'Success';
							eindex.wallData botname, message, actionmsg, statusmsg;
						
						if(stderr)
							console.log(stderr)
							res.send stderr
							setTimeout (->eindex.passData stderr),1000
						
						if(error)
							console.log(error)
							res.send error
							setTimeout (->eindex.passData error),1000
	)

	robot.router.post '/bitbucketcreateproj', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' for the creating project';
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			projectkey = request.body.projectkey;
			projectname = request.body.projectname;
			description = request.body.description;
			# Call from create_project file for project creation 
			createproj.createproj process.env.BITBUCKET_URL, process.env.USERNAME, process.env.PASSWORD, projectkey, projectname, description, (error,stdout,stderr) ->
				if(stdout)
					console.log(stdout)
					res.send stdout
					setTimeout (->eindex.passData stdout),1000
					message = 'bitbucket project created ';
					actionmsg = 'bitbucket project created ';
					statusmsg = 'Success';
					eindex.wallData botname, message, actionmsg, statusmsg;
				
				if(stderr)
					console.log(stderr)
					res.send stderr
					setTimeout (->eindex.passData stderr),1000
				
				if(error)
					console.log(error)
					res.send error
					setTimeout (->eindex.passData error),1000
		else
			dt="create project request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to create bitbucket project.';
				
	cmddeleteproj = new RegExp('@' + process.env.HUBOT_NAME + ' delete project (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddeleteproj
		(res) ->
		
			projectkey=res.match[1]
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				#Action Flow with workflow flag
				if stdout.bitbucketdeleteproj.workflowflag == true
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"bitbucketdeleteproj",projectkey:projectkey}
						data = {"channel": stdout.bitbucketdeleteproj.admin,"text":"Request from "+payload.username+" to deleting bitbucket project "+projectkey,"message":"Request from "+payload.username+" to deleting bitbucket project "+projectkey,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'bitbucketdeleteproj',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							res.send 'Your request is waiting for approval from '+stdout.bitbucketdeleteproj.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Casual workflow
				else
					deleteproj.deleteproj process.env.BITBUCKET_URL, process.env.USERNAME, process.env.PASSWORD, projectkey, (error,stdout,stderr) ->
						if(stdout)
							console.log(stdout)
							res.send stdout
							setTimeout (->eindex.passData stdout),1000
							message = 'bitbucket project deleted ';
							actionmsg = 'bitbucket project deleted ';
							statusmsg = 'Success';
							eindex.wallData botname, message, actionmsg, statusmsg;
						
						if(stderr)
							console.log(stderr)
							res.send stderr
							setTimeout (->eindex.passData stderr),1000
						
						if(error)
							console.log(error)
							res.send error
							setTimeout (->eindex.passData error),1000
	)
	
	robot.router.post '/bitbucketdeleteproj', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' for the deleting project';
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			projectkey = request.body.projectkey;
			# Call from create_project file for project creation 
			deleteproj.deleteproj process.env.BITBUCKET_URL, process.env.USERNAME, process.env.PASSWORD, projectkey, (error,stdout,stderr) ->
				if(stdout)
					console.log(stdout)
					res.send stdout
					setTimeout (->eindex.passData stdout),1000
					message = 'bitbucket project deleted ';
					actionmsg = 'bitbucket project deleted ';
					statusmsg = 'Success';
					eindex.wallData botname, message, actionmsg, statusmsg;
				
				if(stderr)
					console.log(stderr)
					res.send stderr
					setTimeout (->eindex.passData stderr),1000
				
				if(error)
					console.log(error)
					res.send error
					setTimeout (->eindex.passData error),1000
		else
			dt="delete project request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to delete bitbucket project.';
		
	cmdcreaterepo = new RegExp('@' + process.env.HUBOT_NAME + ' create repo (.*) (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreaterepo
		(res) ->
		
			projectkey=res.match[1]
			reponame=res.match[2]
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				#Action Flow with workflow flag
				if stdout.bitbucketcreaterepo.workflowflag == true
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"bitbucketcreaterepo",projectkey:projectkey,reponame:reponame}
						data = {"channel": stdout.bitbucketcreaterepo.admin,"text":"Request from "+payload.username+" to create bitbucket repo "+reponame,"message":"Request from "+payload.username+" to create bitbucket repo "+reponame,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'bitbucketcreaterepo',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							res.send 'Your request is waiting for approval from '+stdout.bitbucketcreaterepo.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Casual workflow
				else
					createrepo.createrepo process.env.BITBUCKET_URL, process.env.USERNAME, process.env.PASSWORD, projectkey, reponame, (error,stdout,stderr) ->
						if(stdout)
							console.log(stdout)
							res.send stdout
							setTimeout (->eindex.passData stdout),1000
							message = 'bitbucket repo created ';
							actionmsg = 'bitbucket repo created ';
							statusmsg = 'Success';
							eindex.wallData botname, message, actionmsg, statusmsg;
						
						if(stderr)
							console.log(stderr)
							res.send stderr
							setTimeout (->eindex.passData stderr),1000
						
						if(error)
							console.log(error)
							res.send error
							setTimeout (->eindex.passData error),1000
	)
						
	robot.router.post '/bitbucketcreaterepo', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' for the creating repo';
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			projectkey = request.body.projectkey;
			reponame = request.body.reponame;
			# Call from create_project file for project creation 
			createrepo.createrepo process.env.BITBUCKET_URL, process.env.USERNAME, process.env.PASSWORD, projectkey, reponame, (error,stdout,stderr) ->
				if(stdout)
					console.log(stdout)
					res.send stdout
					setTimeout (->eindex.passData stdout),1000
					message = 'bitbucket repo created ';
					actionmsg = 'bitbucket repo created ';
					statusmsg = 'Success';
					eindex.wallData botname, message, actionmsg, statusmsg;
				
				if(stderr)
					console.log(stderr)
					res.send stderr
					setTimeout (->eindex.passData stderr),1000
				
				if(error)
					console.log(error)
					res.send error
					setTimeout (->eindex.passData error),1000
		else
			dt="create repo request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized to creating bitbucket repo.';
				
	cmddeleterepo = new RegExp('@' + process.env.HUBOT_NAME + ' delete repo (.*) in (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddeleterepo
		(res) ->
		
			projectkey=res.match[2]
			reponame=res.match[1]
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				#Action Flow with workflow flag
				if stdout.bitbucketdeleterepo.workflowflag == true
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"bitbucketdeleterepo",projectkey:projectkey,reponame:reponame}
						data = {"channel": stdout.bitbucketdeleterepo.admin,"text":"Request from "+payload.username+" to delete bitbucket repo "+reponame,"message":"Request from "+payload.username+" to delete bitbucket repo "+reponame,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'bitbucketdeleterepo',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							res.send 'Your request is waiting for approval from '+stdout.bitbucketdeleterepo.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Casual workflow
				else
					deleterepo.deleterepo process.env.BITBUCKET_URL, process.env.USERNAME, process.env.PASSWORD, projectkey, reponame, (error,stdout,stderr) ->
						if(stdout)
							console.log(stdout)
							res.send stdout
							setTimeout (->eindex.passData stdout),1000
							message = 'bitbucket repo deleted ';
							actionmsg = 'bitbucket repo deleted ';
							statusmsg = 'Success';
							eindex.wallData botname, message, actionmsg, statusmsg;
						
						if(stderr)
							console.log(stderr)
							res.send stderr
							setTimeout (->eindex.passData stderr),1000
						
						if(error)
							console.log(error)
							res.send error
							setTimeout (->eindex.passData error),1000
	)
						
	robot.router.post '/bitbucketdeleterepo', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' for the deleting repo';
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			projectkey = request.body.projectkey;
			reponame = request.body.reponame;
			# Call from create_project file for project creation 
			deleterepo.deleterepo process.env.BITBUCKET_URL, process.env.USERNAME, process.env.PASSWORD, projectkey, reponame, (error,stdout,stderr) ->
				if(stdout)
					console.log(stdout)
					res.send stdout
					setTimeout (->eindex.passData stdout),1000
					message = 'bitbucket repo deleted ';
					actionmsg = 'bitbucket repo deleted ';
					statusmsg = 'Success';
					eindex.wallData botname, message, actionmsg, statusmsg;
				
				if(stderr)
					console.log(stderr)
					res.send stderr
					setTimeout (->eindex.passData stderr),1000
				
				if(error)
					console.log(error)
					res.send error
					setTimeout (->eindex.passData error),1000
		else
			dt="delete repo request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized for deleting bitbucket repo.';
	
	cmdcreatebranch = new RegExp('@' + process.env.HUBOT_NAME + ' create branch (.*) in (.*) repo (.*) from (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreatebranch
		(res) ->
		
			branchname=res.match[1]
			projectkey=res.match[2]
			reposlug=res.match[3]
			frombranch=res.match[4]
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				#Action Flow with workflow flag
				if stdout.bitbucketcreatebranch.workflowflag == true
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"bitbucketcreatebranch",projectkey:projectkey,reposlug:reposlug,branchname:branchname,frombranch:frombranch}
						data = {"channel": stdout.bitbucketcreatebranch.admin,"text":"Request from "+payload.username+" for creating bitbucket branch "+branchname,"message":"Request from "+payload.username+" for creating bitbucket branch "+branchname,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'bitbucketcreatebranch',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							res.send 'Your request is waiting for approval from '+stdout.bitbucketcreatebranch.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Casual workflow
				else
					createbranch.createbranch process.env.BITBUCKET_URL, process.env.USERNAME, process.env.PASSWORD, projectkey, reposlug, branchname, frombranch, (error,stdout,stderr) ->
						if(stdout)
							console.log(stdout)
							res.send stdout
							setTimeout (->eindex.passData stdout),1000
							message = 'bitbucket branch created ';
							actionmsg = 'bitbucket branch created ';
							statusmsg = 'Success';
							eindex.wallData botname, message, actionmsg, statusmsg;
						
						if(stderr)
							console.log(stderr)
							res.send stderr
							setTimeout (->eindex.passData stderr),1000
						
						if(error)
							console.log(error)
							res.send error
							setTimeout (->eindex.passData error),1000
	)
						
	robot.router.post '/bitbucketcreatebranch', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' for the creating branch';
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			projectkey = request.body.projectkey;
			reposlug = request.body.reposlug;
			branchname = request.body.branchname;
			frombranch = request.body.frombranch;
			# Call from create_project file for project creation 
			createbranch.createbranch process.env.BITBUCKET_URL, process.env.USERNAME, process.env.PASSWORD, projectkey, reposlug, branchname, frombranch, (error,stdout,stderr) ->
				if(stdout)
					console.log(stdout)
					res.send stdout
					setTimeout (->eindex.passData stdout),1000
					message = 'bitbucket branch created ';
					actionmsg = 'bitbucket branch created ';
					statusmsg = 'Success';
					eindex.wallData botname, message, actionmsg, statusmsg;
				
				if(stderr)
					console.log(stderr)
					res.send stderr
					setTimeout (->eindex.passData stderr),1000
				
				if(error)
					console.log(error)
					res.send error
					setTimeout (->eindex.passData error),1000
		else
			dt="create branch request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized for creating bitbucket branch.';
			
	cmddeletebranch = new RegExp('@' + process.env.HUBOT_NAME + ' delete branch (.*) from (.*) in (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddeletebranch
		(res) ->
		
			branchname=res.match[1]
			projectkey=res.match[2]
			reposlug=res.match[3]
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				#Action Flow with workflow flag
				if stdout.bitbucketdeletebranch.workflowflag == true
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"bitbucketdeletebranch",projectkey:projectkey,reposlug:reposlug,branchname:branchname}
						data = {"channel": stdout.bitbucketdeletebranch.admin,"text":"Request from "+payload.username+" for deleting bitbucket branch "+branchname,"message":"Request from "+payload.username+" for deleting bitbucket branch "+branchname,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'bitbucketdeletebranch',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							res.send 'Your request is waiting for approval from '+stdout.bitbucketdeletebranch.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Casual workflow
				else
					deletebranch.deletebranch process.env.BITBUCKET_URL, process.env.USERNAME, process.env.PASSWORD, projectkey, reposlug, branchname, (error,stdout,stderr) ->
						if(stdout)
							console.log(stdout)
							res.send stdout
							setTimeout (->eindex.passData stdout),1000
							message = 'bitbucket branch deleted ';
							actionmsg = 'bitbucket branch deleted ';
							statusmsg = 'Success';
							eindex.wallData botname, message, actionmsg, statusmsg;
						
						if(stderr)
							console.log(stderr)
							res.send stderr
							setTimeout (->eindex.passData stderr),1000
						
						if(error)
							console.log(error)
							res.send error
							setTimeout (->eindex.passData error),1000
	)
		
	robot.router.post '/bitbucketdeletebranch', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' for the deleting branch';
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			projectkey = request.body.projectkey;
			reposlug = request.body.reposlug;
			branchname = request.body.branchname;
			# Call from create_project file for project creation 
			deletebranch.deletebranch process.env.BITBUCKET_URL, process.env.USERNAME, process.env.PASSWORD, projectkey, reposlug, branchname, (error,stdout,stderr) ->
				if(stdout)
					console.log(stdout)
					res.send stdout
					setTimeout (->eindex.passData stdout),1000
					message = 'bitbucket branch deleted ';
					actionmsg = 'bitbucket branch deleted ';
					statusmsg = 'Success';
					eindex.wallData botname, message, actionmsg, statusmsg;
				
				if(stderr)
					console.log(stderr)
					res.send stderr
					setTimeout (->eindex.passData stderr),1000
				
				if(error)
					console.log(error)
					res.send error
					setTimeout (->eindex.passData error),1000
		else
			dt="delete branch request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized for deleting bitbucket branch.';
			
	cmdprojpermission = new RegExp('@' + process.env.HUBOT_NAME + ' project permission (.*) to (.*) for (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdprojpermission
		(res) ->
		
			permission=res.match[1]
			user=res.match[2]
			projectkey=res.match[3]
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				#Action Flow with workflow flag
				if stdout.bitbucketprojpermission.workflowflag == true
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"bitbucketprojpermission",projectkey:projectkey,permission:permission,user:user}
						data = {"channel": stdout.bitbucketprojpermission.admin,"text":"Request from "+payload.username+" to provide project permission "+permission+" to user "+user,"message":"Request from "+payload.username+" to provide project permission "+permission+" to user "+user,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'bitbucketprojpermission',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							res.send 'Your request is waiting for approval from '+stdout.bitbucketprojpermission.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Casual workflow
				else
					projpermission.projpermission process.env.BITBUCKET_URL, process.env.USERNAME, process.env.PASSWORD, projectkey, user, permission, (error,stdout,stderr) ->
						if(stdout)
							console.log(stdout)
							res.send stdout
							setTimeout (->eindex.passData stdout),1000
						
						if(stderr)
							console.log(stderr)
							res.send stderr
							setTimeout (->eindex.passData stderr),1000
						
						if(error)
							console.log(error)
							res.send error
							setTimeout (->eindex.passData error),1000
	)
						
	robot.router.post '/bitbucketprojpermission', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' for providing project permission to user';
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			projectkey = request.body.projectkey;
			user = request.body.user;
			permission = request.body.permission;
			# Call from create_project file for project creation 
			projpermission.projpermission process.env.BITBUCKET_URL, process.env.USERNAME, process.env.PASSWORD, projectkey, user, permission, (error,stdout,stderr) ->
				if(stdout)
					console.log(stdout)
					res.send stdout
					setTimeout (->eindex.passData stdout),1000
				
				if(stderr)
					console.log(stderr)
					res.send stderr
					setTimeout (->eindex.passData stderr),1000
				
				if(error)
					console.log(error)
					res.send error
					setTimeout (->eindex.passData error),1000
		else
			dt="providing project permsiion to user request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized for providing project permission to user.';
				
	cmduserpermission = new RegExp('@' + process.env.HUBOT_NAME + ' (.*) permission (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmduserpermission
		(res) ->
		
			user=res.match[1]
			permission=res.match[2]
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				#Action Flow with workflow flag
				if stdout.bitbucketuserpermission.workflowflag == true
					#Generate Random Ticket Number
					generate_id.getNextSequence (err,id) ->
						tckid=id
						payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"bitbucketuserpermission",permission:permission,user:user}
						data = {"channel": stdout.bitbucketuserpermission.admin,"text":"Request from "+payload.username+" to provide premission "+permission+" to user "+user,"message":"Request from "+payload.username+" to provide premission "+permission+" to user "+user,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'bitbucketuserpermission',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approve",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Reject",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
							res.send 'Your request is waiting for approval from '+stdout.bitbucketuserpermission.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						generate_id.add_in_mongo dataToInsert
				#Casual workflow
				else
					userpermission.userpermission process.env.BITBUCKET_URL, process.env.USERNAME, process.env.PASSWORD, user, permission, (error,stdout,stderr) ->
						if(stdout)
							console.log(stdout)
							res.send stdout
							setTimeout (->eindex.passData stdout),1000
						
						if(stderr)
							console.log(stderr)
							res.send stderr
							setTimeout (->eindex.passData stderr),1000
						
						if(error)
							console.log(error)
							res.send error
							setTimeout (->eindex.passData error),1000
	)
						
	robot.router.post '/bitbucketuserpermission', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == "Approve"
			dt='Your request is approved by '+data_http.approver+' for providing permission to user';
			# Approved Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			user = request.body.user;
			permission = request.body.permission;
			# Call from create_project file for project creation 
			userpermission.userpermission process.env.BITBUCKET_URL, process.env.USERNAME, process.env.PASSWORD, user, permission, (error,stdout,stderr) ->
				if(stdout)
					console.log(stdout)
					res.send stdout
					setTimeout (->eindex.passData stdout),1000
				
				if(stderr)
					console.log(stderr)
					res.send stderr
					setTimeout (->eindex.passData stderr),1000
				
				if(error)
					console.log(error)
					res.send error
					setTimeout (->eindex.passData error),1000
		else
			dt="providing permsiion to user request was rejected by "+data_http.approver
			setTimeout (->eindex.passData dt),1000
			# Rejected Message send to the user chat room
			robot.messageRoom data_http.userid, dt;
			robot.messageRoom data_http.userid, 'Sorry, You are not authorized for providing permission to user.';
