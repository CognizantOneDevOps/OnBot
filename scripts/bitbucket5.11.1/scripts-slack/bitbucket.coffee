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
	robot.respond /help/, (res) ->
		res.send "list repo-->list repo <prjkey>\nlist projects-->list projects\ncreate user-->create user <username> <pwd> <email>\nprovide permission to user for project-->project permission <permission> to <user> for <prjkey>(possible permissions::PROJECT_READ,PROJECT_WRITE,PROJECT_ADMIN)\ngrant user permission--><user> premission <permission>(possible permissions::LICENSED_USER,PROJECT_CREATE,ADMIN,SYS_ADMIN)\ndelete user-->delete user <username>\ncreate project-->create project <prjkey> with  <prjname> desc <prjdecsc>\ndelete project-->delete project <prj key>\ncreate repo-->create repo <prjkey> <reponame>\ndelete repo-->delete repo <reposlug> in <prjkey>\ncreate branch-->create branch <branchname> in <prjkey> repo <reposlug> from <frombranch>\ndelete branch--> delete branch <branchname> from <prjkey> in <reposlug>" 

	robot.respond /list repo (.*)/, (res) ->
	
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

	robot.respond /list projects/, (res) ->
	
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

	robot.respond /create user (.*) (.*) (.*)/, (res) ->
		
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
					message = {"text": "Request from "+payload.username+" to create bitbucket user "+user,"attachments": [{"text": "You can Approve or Reject","fallback": "failed to respond","callback_id": "bitbucketcreateuser","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approve","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.bitbucketcreateuser.adminid, message);
					res.send 'Your request is waiting for approval by '+stdout.bitbucketcreateuser.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
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

	robot.respond /delete user (.*)/, (res) -> 
		
		user=res.match[1]
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
			if stdout.bitbucketdeleteuser.workflowflag == true
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"bitbucketdeleteuser",user:user}
					message = {"text": "Request from "+payload.username+" to delete bitbucket user "+user,"attachments": [{"text": "You can Approve or Reject","fallback": "failed to respond","callback_id": "bitbucketdeleteuser","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approve","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.bitbucketdeleteuser.adminid, message);
					res.send 'Your request is waiting for approval by '+stdout.bitbucketdeleteuser.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
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
				
	robot.respond /create project (.*) with (.*) desc (.*)/, (res) -> 
		
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
					message = {"text": "Request from "+payload.username+" to create bitbucket project "+projectname,"attachments": [{"text": "You can Approve or Reject","fallback": "failed to respond","callback_id": "bitbucketcreateproj","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approve","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.bitbucketcreateproj.adminid, message);
					res.send 'Your request is waiting for approval by '+stdout.bitbucketcreateproj.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
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
				
	robot.respond /delete project (.*)/, (res) ->
		
		projectkey=res.match[1]
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
			if stdout.bitbucketdeleteproj.workflowflag == true
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"bitbucketdeleteproj",projectkey:projectkey}
					message = {"text": "Request from "+payload.username+" to deleting bitbucket project "+projectkey,"attachments": [{"text": "You can Approve or Reject","fallback": "failed to respond","callback_id": "bitbucketdeleteproj","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approve","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.bitbucketdeleteproj.adminid, message);
					res.send 'Your request is waiting for approval by '+stdout.bitbucketdeleteproj.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
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
		
	robot.respond /create repo (.*) (.*)/, (res) ->
		
		projectkey=res.match[1]
		reponame=res.match[2]
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
			if stdout.bitbucketcreaterepo.workflowflag == true
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"bitbucketcreaterepo",projectkey:projectkey,reponame:reponame}
					message = {"text": "Request from "+payload.username+" to create bitbucket repo "+reponame,"attachments": [{"text": "You can Approve or Reject","fallback": "failed to respond","callback_id": "bitbucketcreaterepo","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approve","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.bitbucketcreaterepo.adminid, message);
					res.send 'Your request is waiting for approval by '+stdout.bitbucketcreaterepo.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
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
				
	robot.respond /delete repo (.*) in (.*)/, (res) ->
		
		projectkey=res.match[2]
		reponame=res.match[1]
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
			if stdout.bitbucketdeleterepo.workflowflag == true
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"bitbucketdeleterepo",projectkey:projectkey,reponame:reponame}
					message = {"text": "Request from "+payload.username+" to delete bitbucket repo "+reponame,"attachments": [{"text": "You can Approve or Reject","fallback": "failed to respond","callback_id": "bitbucketdeleterepo","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approve","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.bitbucketdeleterepo.adminid, message);
					res.send 'Your request is waiting for approval by '+stdout.bitbucketdeleterepo.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
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
	
	robot.respond /create branch (.*) in (.*) repo (.*) from (.*)/, (res) ->
		
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
					message = {"text": "Request from "+payload.username+" for creating bitbucket branch "+branchname,"attachments": [{"text": "You can Approve or Reject","fallback": "failed to respond","callback_id": "bitbucketcreatebranch","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approve","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.bitbucketcreatebranch.adminid, message);
					res.send 'Your request is waiting for approval by '+stdout.bitbucketcreatebranch.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
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
			
	robot.respond /delete branch (.*) from (.*) in (.*)/, (res) ->
		
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
					message = {"text": "Request from "+payload.username+" for deleting bitbucket branch "+branchname,"attachments": [{"text": "You can Approve or Reject","fallback": "failed to respond","callback_id": "bitbucketdeletebranch","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approve","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.bitbucketdeletebranch.adminid, message);
					res.send 'Your request is waiting for approval by '+stdout.bitbucketdeletebranch.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
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
				
	robot.respond /project permission (.*) to (.*) for (.*)/, (res) ->
		
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
					message = {"text": "Request from "+payload.username+" to provide project permission "+permission+" to user "+user,"attachments": [{"text": "You can Approve or Reject","fallback": "failed to respond","callback_id": "bitbucketprojpermission","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approve","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.bitbucketprojpermission.adminid, message);
					res.send 'Your request is waiting for approval by '+stdout.bitbucketprojpermission.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
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
				
	robot.respond /(.*) permission (.*)/, (res) ->
		
		user=res.match[1]
		permission=res.match[2]
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			#Action Flow with workflow flag
			if stdout.bitbucketuserpermission.workflowflag == true
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.id,podIp:process.env.MY_POD_IP,"callback_id":"bitbucketuserpermission",permission:permission,user:user}
					message = {"text": "Request from "+payload.username+" to provide premission "+permission+" to user "+user,"attachments": [{"text": "You can Approve or Reject","fallback": "failed to respond","callback_id": "bitbucketuserpermission","color":"#3AA3E3","attachment_type":"default","actions":[{"name":"Approve","text":"Approve","type":"button","value":tckid},{"name":"Rejected","text": "Reject","type": "button","value": tckid,"style": "danger",confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom(stdout.bitbucketuserpermission.adminid, message);
					res.send 'Your request is waiting for approval by '+stdout.bitbucketuserpermission.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
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
