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
# Hubot configured to work with JFrogArtifactory6.0.3
#
#Configurations:
#
#
#Commands:
# help -> display list of commands that this bot can perform
#

repos = require('./requesthandlers.js')
index = require('./index')
readjson = require './readjson.js'
finaljson=" ";
generate_id = require('./mongoConnt')
request = require("request")

module.exports = (robot) ->
	robot.respond /help/i, (msg) ->
		dt = 'Here are the commands I can perform for you:\ngetRepos-> get list of all repositories(except virtual)\ngetArtifact <artifactname_with_extension> <reponame>-> get a download link for the artifact\ncreateRepo <repotype> <reponame>-> create a repository with the given reponame *(:information_source: Valid repotypes are: local, remote, virtual [case sensitive])*\ndeleteRepo <reponame>-> delete the given repo\ngetUsers-> get list of all users\ncreateUser <username> <email>-> create a user with given username and email *(:warning: giving an already existing username will overwrite the existing user deatils and privileges)*\ndeleteUser <username>-> delete the given user\nupload <local_path_of_artifact> <reponame/remote_path_of_artifact>-> upload artifact to the given remote path\ndeleteArtifact <reponame/remote_path_of_artifact>-> delete the artifact residing at the given remote path\nSo, how may I help you?:frog:'
		msg.send dt
		setTimeout (->index.passData dt),1000
	
	robot.respond /getRepos/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			if stdout.getrepos.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,podIp:process.env.MY_POD_IP,"callback_id":"getrepos",approver:stdout.getrepos.admin}
					data = {text: 'Approve Request',attachments: [{text: payload.username+' requested to get list of repositories in Artifactory',fallback: 'Yes or No?',callback_id: 'getrepos',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approved', text: 'Approved', type: 'button', value: tckid,confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Approve','dismiss_text': 'Cancel'} },{ name: 'Rejected', text: 'Rejected',  type: 'button',  value: tckid,'style':'danger',confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Reject','dismiss_text': 'Cancel'}}]}]}
					robot.messageRoom stdout.getrepos.adminid,data
					msg.send 'Your request is waiting for approval by '+stdout.getrepos.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				repos.getrepos (error, stdout) ->
					if error
						msg.send error
						setTimeout (->index.passData error),1000
					else
						msg.send stdout
						setTimeout (->index.passData stdout),1000
	
	robot.router.post '/getrepos', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved request to get list of repos from "+req.body.username+"\n"
			robot.messageRoom recipientid, dt
			repos.getrepos (error, stdout) ->
				if error
					robot.messageRoom recipientid, error
					setTimeout (->index.passData error),1000
				else
					robot.messageRoom recipientid, stdout
					setTimeout (->index.passData stdout),1000
		else
			dt="The request from "+req.body.username+" to view list of repos was rejected by "+req.body.approver
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
	
	robot.respond /getArtifact (.+)/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			artifact = msg.match[1].split(' ')[0]
			repo = msg.match[1].split(' ')[1]
			if stdout.getartifact.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,podIp:process.env.MY_POD_IP,"callback_id":"getartifact",artifact:artifact,repo:repo,approver:stdout.getartifact.admin}
					data = {text: 'Approve Request',attachments: [{text: payload.username+' requested to get artifact named '+payload.artifact,fallback: 'Yes or No?',callback_id: 'getartifact',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approved', text: 'Approved', type: 'button', value: tckid,confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Approve','dismiss_text': 'Cancel'} },{ name: 'Rejected', text: 'Rejected',  type: 'button',  value: tckid,'style':'danger',confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Reject','dismiss_text': 'Cancel'}}]}]}
					robot.messageRoom stdout.getartifact.adminid,data
					msg.send 'Your request is waiting for approval by '+stdout.getartifact.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				repos.get_artifact repo, artifact, (error, stdout) ->
					if error
						msg.send error
						setTimeout (->index.passData error),1000
					else
						msg.send stdout
						setTimeout (->index.passData stdout),1000
	
	robot.router.post '/getartifact', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved request to get artifact from "+req.body.username+"\n"
			robot.messageRoom recipientid, dt
			repo = req.body.repo
			artifact = req.body.artifact
			repos.get_artifact repo, artifact, (error, stdout) ->
				if error
					robot.messageRoom recipientid, error
					setTimeout (->index.passData error),1000
				else
					robot.messageRoom recipientid, stdout
					setTimeout (->index.passData stdout),1000
		else
			dt="The request from "+req.body.username+" to get artifact was rejected by "+req.body.approver
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
	
	robot.respond /createRepo (.+)/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			repotype = msg.match[1].split(' ')[0]
			repokey = msg.match[1].split(' ')[1]
			if stdout.createrepo.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,podIp:process.env.MY_POD_IP,"callback_id":"createrepo",repotype:repotype,repokey:repokey,approver:stdout.createrepo.admin}
					data = {text: 'Approve Request',attachments: [{text: payload.username+' requested to create repo named '+payload.repokey,fallback: 'Yes or No?',callback_id: 'createrepo',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approved', text: 'Approved', type: 'button', value: tckid,confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Approve','dismiss_text': 'Cancel'} },{ name: 'Rejected', text: 'Rejected',  type: 'button',  value: tckid,'style':'danger',confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Reject','dismiss_text': 'Cancel'}}]}]}
					robot.messageRoom stdout.createrepo.adminid,data
					msg.send 'Your request is waiting for approval by '+stdout.createrepo.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				repos.create_repo repokey, repotype, (error, stdout) ->
					if error
						msg.send error
						setTimeout (->index.passData error),1000
					else
						msg.send stdout
						setTimeout (->index.passData stdout),1000
	
	robot.router.post '/createrepo', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved request to create repo from "+req.body.username+"\n"
			robot.messageRoom recipientid, dt
			repokey = req.body.repokey
			repotype = req.body.repotype
			repos.create_repo repokey, repotype, (error, stdout) ->
				if error
					robot.messageRoom recipientid, error
					setTimeout (->index.passData error),1000
				else
					robot.messageRoom recipientid, stdout
					setTimeout (->index.passData stdout),1000
		else
			dt="The request from "+req.body.username+" to create repo was rejected by "+req.body.approver
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
		response.send "Success from bot"
	
	robot.respond /deleteRepo (.*)/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			repokey = msg.match[1]
			if stdout.deleterepo.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,podIp:process.env.MY_POD_IP,"callback_id":"deleterepo",repokey:repokey,approver:stdout.deleterepo.admin}
					data = {text: 'Approve Request',attachments: [{text: payload.username+' requested to delete repo named '+payload.repokey,fallback: 'Yes or No?',callback_id: 'deleterepo',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approved', text: 'Approved', type: 'button', value: tckid,confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Approve','dismiss_text': 'Cancel'} },{ name: 'Rejected', text: 'Rejected',  type: 'button',  value: tckid,'style':'danger',confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Reject','dismiss_text': 'Cancel'}}]}]}
					robot.messageRoom stdout.deleterepo.adminid,data
					msg.send 'Your request is waiting for approval by '+stdout.deleterepo.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				repos.delete_repo repokey, (error, stdout) ->
					if error
						msg.send error
						setTimeout (->index.passData error),1000
					else
						msg.send stdout
						setTimeout (->index.passData stdout),1000
	
	robot.router.post '/deleterepo', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved request to delete repo from "+req.body.username+"\n"
			robot.messageRoom recipientid, dt
			repokey = req.body.repokey
			repos.delete_repo repokey, (error, stdout) ->
				if error
					robot.messageRoom recipientid, error
					setTimeout (->index.passData error),1000
				else
					robot.messageRoom recipientid, stdout
					setTimeout (->index.passData stdout),1000
		else
			dt="The request from "+req.body.username+" to delete repo was rejected by "+req.body.approver
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
	
	robot.respond /getUsers/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			if stdout.getusers.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,podIp:process.env.MY_POD_IP,"callback_id":"getusers",approver:stdout.getusers.admin}
					data = {text: 'Approve Request',attachments: [{text: payload.username+' requested to get list of users in Artifactory',fallback: 'Yes or No?',callback_id: 'getusers',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approved', text: 'Approved', type: 'button', value: tckid,confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Approve','dismiss_text': 'Cancel'} },{ name: 'Rejected', text: 'Rejected',  type: 'button',  value: tckid,'style':'danger',confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Reject','dismiss_text': 'Cancel'}}]}]}
					robot.messageRoom stdout.getusers.adminid,data
					msg.send 'Your request is waiting for approval by '+stdout.getusers.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				repos.get_users (error, stdout) ->
					if error
						msg.send error
						setTimeout (->index.passData error),1000
					else
						msg.send stdout
						setTimeout (->index.passData stdout),1000
	
	robot.router.post '/getusers', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved request to get list of users from "+req.body.username+"\n"
			robot.messageRoom recipientid, dt
			repokey = req.body.repokey
			repos.get_users (error, stdout) ->
				if error
					robot.messageRoom recipientid, error
					setTimeout (->index.passData error),1000
				else
					robot.messageRoom recipientid, stdout
					setTimeout (->index.passData stdout),1000
		else
			dt="The request from "+req.body.username+" to view list of users was rejected by "+req.body.approver
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
	
	robot.respond /createUser (.+)/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			user = msg.match[1].split(' ')[0]
			email = msg.match[1].split(' ')[1]
			if stdout.createuser.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,podIp:process.env.MY_POD_IP,"callback_id":"createuser",user:user,email:email,approver:stdout.createuser.admin}
					data = {text: 'Approve Request',attachments: [{text: payload.username+' requested to create user named '+payload.user+' with email '+payload.email+' in Artifactory',fallback: 'Yes or No?',callback_id: 'createuser',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approved', text: 'Approved', type: 'button', value: tckid,confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Approve','dismiss_text': 'Cancel'} },{ name: 'Rejected', text: 'Rejected',  type: 'button',  value: tckid,'style':'danger',confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Reject','dismiss_text': 'Cancel'}}]}]}
					robot.messageRoom stdout.createuser.adminid,data
					msg.send 'Your request is waiting for approval by '+stdout.createuser.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				repos.create_user user, email, (error, stdout) ->
					if error
						msg.send error
						setTimeout (->index.passData error),1000
					else
						msg.send stdout
						setTimeout (->index.passData stdout),1000
	
	robot.router.post '/createuser', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved request to create user from "+req.body.username+"\n"
			robot.messageRoom recipientid, dt
			user = req.body.user
			email = req.body.email
			repos.create_user user, email, (error, stdout) ->
				if error
					robot.messageRoom recipientid, error
					setTimeout (->index.passData error),1000
				else
					robot.messageRoom recipientid, stdout
					setTimeout (->index.passData stdout),1000
		else
			dt="The request from "+req.body.username+" to create user was rejected by "+req.body.approver
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
	
	robot.respond /deleteUser (.*)/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			user = msg.match[1]
			if stdout.deleteuser.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,podIp:process.env.MY_POD_IP,"callback_id":"deleteuser",user:user,approver:stdout.deleteuser.admin}
					data = {text: 'Approve Request',attachments: [{text: payload.username+' requested to delete user named '+payload.user+' in Artifactory',fallback: 'Yes or No?',callback_id: 'deleteuser',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approved', text: 'Approved', type: 'button', value: tckid,confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Approve','dismiss_text': 'Cancel'} },{ name: 'Rejected', text: 'Rejected',  type: 'button',  value: tckid,'style':'danger',confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Reject','dismiss_text': 'Cancel'}}]}]}
					robot.messageRoom stdout.deleteuser.adminid,data
					msg.send 'Your request is waiting for approval by '+stdout.deleteuser.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				repos.delete_user user, (error, stdout) ->
					if error
						msg.send error
						setTimeout (->index.passData error),1000
					else
						msg.send stdout
						setTimeout (->index.passData stdout),1000
	
	robot.router.post '/deleteuser', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved request to delete user from "+req.body.username+"\n"
			robot.messageRoom recipientid, dt
			user = req.body.user
			repos.delete_user user, (error, stdout) ->
				if error
					robot.messageRoom recipientid, error
					setTimeout (->index.passData error),1000
				else
					robot.messageRoom recipientid, stdout
					setTimeout (->index.passData stdout),1000
		else
			dt="The request from "+req.body.username+" to view list of repos was rejected by "+req.body.approver
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
	
	robot.respond /upload (.+)/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			local_path = msg.match[1].split(' ')[0]
			remote_path = msg.match[1].split(' ')[1]
			if stdout.uploadartifact.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,podIp:process.env.MY_POD_IP,"callback_id":"uploadartifact",local_path:local_path,remote_path:remote_path,approver:stdout.uploadartifact.admin}
					data = {text: 'Approve Request',attachments: [{text: payload.username+' requested to upload artifact from local path: '+payload.local_path+' to this remote path: '+payload.remote_path,fallback: 'Yes or No?',callback_id: 'uploadartifact',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approved', text: 'Approved', type: 'button', value: tckid,confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Approve','dismiss_text': 'Cancel'} },{ name: 'Rejected', text: 'Rejected',  type: 'button',  value: tckid,'style':'danger',confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Reject','dismiss_text': 'Cancel'}}]}]}
					robot.messageRoom stdout.uploadartifact.adminid,data
					msg.send 'Your request is waiting for approval by '+stdout.uploadartifact.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				console.log("uploading..")
				repos.upload_artifact remote_path, local_path, (error, stdout) ->
					if error
						msg.send error
						setTimeout (->index.passData error),1000
					else
						msg.send stdout
						setTimeout (->index.passData stdout),1000
	
	robot.router.post '/uploadartifact', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved request to upload artifact from "+req.body.username+"\n"
			robot.messageRoom recipientid, dt
			local_path = req.body.local_path
			remote_path = req.body.remote_path
			repos.upload_artifact remote_path, local_path, (error, stdout) ->
				if error
					robot.messageRoom recipientid, error
					setTimeout (->index.passData error),1000
				else
					robot.messageRoom recipientid, stdout
					setTimeout (->index.passData stdout),1000
		else
			dt="The request from "+req.body.username+" to upload artifact was rejected by "+req.body.approver
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
	
	robot.respond /deleteArtifact (.*)/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			remote_path = msg.match[1]
			if stdout.deleteartifact.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,podIp:process.env.MY_POD_IP,"callback_id":"deleteartifact",remote_path:remote_path,approver:stdout.deleteartifact.admin}
					data = {text: 'Approve Request',attachments: [{text: payload.username+' requested to delete artifact from remote path: '+payload.remote_path,fallback: 'Yes or No?',callback_id: 'deleteartifact',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approved', text: 'Approved', type: 'button', value: tckid,confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Approve','dismiss_text': 'Cancel'} },{ name: 'Rejected', text: 'Rejected',  type: 'button',  value: tckid,'style':'danger',confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Reject','dismiss_text': 'Cancel'}}]}]}
					robot.messageRoom stdout.deleteartifact.adminid,data
					msg.send 'Your request is waiting for approval by '+stdout.deleteartifact.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				repos.delete_artifact remote_path, (error, stdout) ->
					if error
						msg.send error
						setTimeout (->index.passData error),1000
					else
						msg.send stdout
						setTimeout (->index.passData stdout),1000
	
	robot.router.post '/deleteartifact', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved request to delete artifact from "+req.body.username+"\n"
			robot.messageRoom recipientid, dt
			remote_path = req.body.remote_path
			repos.delete_artifact remote_path, (error, stdout) ->
				if error
					robot.messageRoom recipientid, error
					setTimeout (->index.passData error),1000
				else
					robot.messageRoom recipientid, stdout
					setTimeout (->index.passData stdout),1000
		else
			dt="The request from "+req.body.username+" to delete artifact was rejected by "+req.body.approver
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
