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
	cmdhelp = new RegExp('@' + process.env.HUBOT_NAME + ' help')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdhelp
		(msg) ->
			dt = 'Here are the commands I can perform for you:\ngetRepos-> get list of all repositories(except virtual)\ngetArtifact <artifactname_with_extension> <reponame>-> get a download link for the artifact\ncreateRepo <repotype> <reponame>-> create a repository with the given reponame **(:information_source: Valid repotypes are: local, remote, virtual [case sensitive])**\ndeleteRepo <reponame>-> delete the given repo\ngetUsers-> get list of all users\ncreateUser <username> <email>-> create a user with given username and email**(:warning: giving an already existing username will overwrite the existing user deatils and privileges)**\ndeleteUser <username>-> delete the given user\nupload <local_path_of_artifact> <reponame/remote_path_of_artifact>-> upload artifact to the given remote path\ndelete <reponame/remote_path_of_artifact>-> delete the artifact residing at the given remote path\nSo, how may I help you?:robot:'
			msg.send dt
			setTimeout (->index.passData dt),1000
	)
	
	cmdgetrepo = new RegExp('@' + process.env.HUBOT_NAME + ' getRepos')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdgetrepo
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				finaljson=stdout;
				if stdout.getrepos.workflowflag
					generate_id.getNextSequence (err,id) ->
						tckid=id
						console.log(tckid);
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,podIp:process.env.MY_POD_IP,"callback_id":"getrepos",approver:stdout.getrepos.admin}
						data = {"channel": stdout.getrepos.admin,"text":"Request from "+payload.username,"message":"Approve Request from "+payload.username+" to get list of repositories",attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'getrepos',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
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
	)
	
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
	
	cmdgetartifact = new RegExp('@' + process.env.HUBOT_NAME + ' getArtifact (.+)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdgetartifact
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				finaljson=stdout;
				artifact = msg.match[1].split(' ')[0]
				repo = msg.match[1].split(' ')[1]
				if stdout.getartifact.workflowflag
					generate_id.getNextSequence (err,id) ->
						tckid=id
						console.log(tckid);
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,podIp:process.env.MY_POD_IP,"callback_id":"getartifact",artifact:artifact,repo:repo,approver:stdout.getartifact.admin}
						data = {"channel": stdout.getartifact.admin,"text":"Request from "+payload.username,"message":"Approve Request from "+payload.username+" to get artifact named "+artifact,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'getartifact',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
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
	)
	
	robot.router.post '/getartifact', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved request to get artifact from "+req.body.username+"\n"
			robot.messageRoom recipientid, dt
			repo = req.body.repo
			artifact = req.body.artifact
			repos.get_artifact repo, artifact, (error, stdout) ->
				if error
					msg.send error
					setTimeout (->index.passData error),1000
				else
					msg.send stdout
					setTimeout (->index.passData stdout),1000
		else
			dt="The request from "+req.body.username+" to get artifact was rejected by "+req.body.approver
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
	
	cmdcreaterepo = new RegExp('@' + process.env.HUBOT_NAME + ' createRepo (.+)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreaterepo
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				finaljson=stdout;
				repotype = msg.match[1].split(' ')[0]
				repokey = msg.match[1].split(' ')[1]
				if stdout.createrepo.workflowflag
					generate_id.getNextSequence (err,id) ->
						tckid=id
						console.log(tckid);
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,podIp:process.env.MY_POD_IP,"callback_id":"createrepo",repotype:repotype,repokey:repokey,approver:stdout.createrepo.admin}
						data = {"channel": stdout.createrepo.admin,"text":"Request from "+payload.username,"message":"Approve Request from "+payload.username+" to create repo named "+repokey,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'createrepo',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
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
	)
	
	robot.router.post '/createrepo', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved request to create repo from "+req.body.username+"\n"
			robot.messageRoom recipientid, dt
			repokey = req.body.repokey
			repotype = req.body.repotype
			repos.create_repo repokey, repotype, (error, stdout) ->
				if error
					msg.send error
					setTimeout (->index.passData error),1000
				else
					msg.send stdout
					setTimeout (->index.passData stdout),1000
		else
			dt="The request from "+req.body.username+" to create repo was rejected by "+req.body.approver
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
	
	cmddeleterepo = new RegExp('@' + process.env.HUBOT_NAME + ' deleteRepo (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddeleterepo
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				finaljson=stdout;
				repokey = msg.match[1]
				if stdout.deleterepo.workflowflag
					generate_id.getNextSequence (err,id) ->
						tckid=id
						console.log(tckid);
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,podIp:process.env.MY_POD_IP,"callback_id":"deleterepo",repokey:repokey,approver:stdout.deleterepo.admin}
						data = {"channel": stdout.deleterepo.admin,"text":"Request from "+payload.username,"message":"Approve Request from "+payload.username+" to delete repo named "+repokey,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'deleterepo',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
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
	)
	
	robot.router.post '/deleterepo', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved request to delete repo from "+req.body.username+"\n"
			robot.messageRoom recipientid, dt
			repokey = req.body.repokey
			repos.delete_repo repokey, (error, stdout) ->
				if error
					msg.send error
					setTimeout (->index.passData error),1000
				else
					msg.send stdout
					setTimeout (->index.passData stdout),1000
		else
			dt="The request from "+req.body.username+" to delete repo was rejected by "+req.body.approver
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
	
	cmdgetusers = new RegExp('@' + process.env.HUBOT_NAME + ' getUsers')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdgetusers
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				finaljson=stdout;
				if stdout.getusers.workflowflag
					generate_id.getNextSequence (err,id) ->
						tckid=id
						console.log(tckid);
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,podIp:process.env.MY_POD_IP,"callback_id":"getusers",approver:stdout.getusers.admin}
						data = {"channel": stdout.getusers.admin,"text":"Request from "+payload.username,"message":"Approve Request from "+payload.username+" to delete repo named "+repokey,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'getusers',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
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
	)
	
	robot.router.post '/getusers', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved request to get list of users from "+req.body.username+"\n"
			robot.messageRoom recipientid, dt
			repokey = req.body.repokey
			repos.get_users (error, stdout) ->
				if error
					msg.send error
					setTimeout (->index.passData error),1000
				else
					msg.send stdout
					setTimeout (->index.passData stdout),1000
		else
			dt="The request from "+req.body.username+" to view list of users was rejected by "+req.body.approver
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
	
	cmdcreateuser = new RegExp('@' + process.env.HUBOT_NAME + ' createUser (.+)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreateuser
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				finaljson=stdout;
				user = msg.match[1].split(' ')[0]
				email = msg.match[1].split(' ')[1]
				if stdout.createuser.workflowflag
					generate_id.getNextSequence (err,id) ->
						tckid=id
						console.log(tckid);
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,podIp:process.env.MY_POD_IP,"callback_id":"createuser",user:user,email:email,approver:stdout.createuser.admin}
						data = {"channel": stdout.createuser.admin,"text":"Request from "+payload.username,"message":"Approve Request from "+payload.username+" to create user named "+user+" with email: "+email,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'createuser',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
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
	)
	
	robot.router.post '/createuser', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved request to create user from "+req.body.username+"\n"
			robot.messageRoom recipientid, dt
			user = req.body.user
			email = req.body.email
			repos.create_user user, email, (error, stdout) ->
				if error
					msg.send error
					setTimeout (->index.passData error),1000
				else
					msg.send stdout
					setTimeout (->index.passData stdout),1000
		else
			dt="The request from "+req.body.username+" to create user was rejected by "+req.body.approver
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
	
	cmddeleteuser = new RegExp('@' + process.env.HUBOT_NAME + ' deleteUser (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddeleteuser
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				finaljson=stdout;
				user = msg.match[1]
				if stdout.deleteuser.workflowflag
					generate_id.getNextSequence (err,id) ->
						tckid=id
						console.log(tckid);
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,podIp:process.env.MY_POD_IP,"callback_id":"deleteuser",user:user,approver:stdout.deleteuser.admin}
						data = {"channel": stdout.deleteuser.admin,"text":"Request from "+payload.username,"message":"Approve Request from "+payload.username+" to delete user named "+user,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'deleteuser',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
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
	)
	
	robot.router.post '/deleteuser', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved request to delete user from "+req.body.username+"\n"
			robot.messageRoom recipientid, dt
			user = req.body.user
			repos.delete_user user, (error, stdout) ->
				if error
					msg.send error
					setTimeout (->index.passData error),1000
				else
					msg.send stdout
					setTimeout (->index.passData stdout),1000
		else
			dt="The request from "+req.body.username+" to view list of repos was rejected by "+req.body.approver
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
	
	cmduploadartifact = new RegExp('@' + process.env.HUBOT_NAME + ' upload (.+)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmduploadartifact
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				finaljson=stdout;
				local_path = msg.match[1].split(' ')[0]
				remote_path = msg.match[1].split(' ')[1]
				if stdout.uploadartifact.workflowflag
					generate_id.getNextSequence (err,id) ->
						tckid=id
						console.log(tckid);
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,podIp:process.env.MY_POD_IP,"callback_id":"uploadartifact",local_path:local_path,remote_path:remote_path,approver:stdout.uploadartifact.admin}
						data = {"channel": stdout.uploadartifact.admin,"text":"Request from "+payload.username,"message":"Approve Request from "+payload.username+" to delete user named "+user,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'uploadartifact',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval by '+stdout.uploadartifact.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						#Insert into Mongo with Payload
						generate_id.add_in_mongo dataToInsert
				else
					repos.upload_artifact remote_path, local_path, (error, stdout) ->
						if error
							msg.send error
							setTimeout (->index.passData error),1000
						else
							msg.send stdout
							setTimeout (->index.passData stdout),1000
	)
	
	robot.router.post '/uploadartifact', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved request to upload artifact from "+req.body.username+"\n"
			robot.messageRoom recipientid, dt
			local_path = req.body.local_path
			remote_path = req.body.remote_path
			repos.upload_artifact remote_path, local_path, (error, stdout) ->
				if error
					msg.send error
					setTimeout (->index.passData error),1000
				else
					msg.send stdout
					setTimeout (->index.passData stdout),1000
		else
			dt="The request from "+req.body.username+" to upload artifact was rejected by "+req.body.approver
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
	
	cmddeleteartifact = new RegExp('@' + process.env.HUBOT_NAME + ' deleteArtifact (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddeleteartifact
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				finaljson=stdout;
				remote_path = msg.match[1]
				if stdout.deleteartifact.workflowflag
					generate_id.getNextSequence (err,id) ->
						tckid=id
						console.log(tckid);
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,podIp:process.env.MY_POD_IP,"callback_id":"deleteartifact",remote_path:remote_path,approver:stdout.deleteartifact.admin}
						data = {"channel": stdout.deleteartifact.admin,"text":"Request from "+payload.username,"message":"Approve Request from "+payload.username+" to delete artifact at this remote path: "+remote_path,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'deleteartifact',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
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
	)
	
	robot.router.post '/deleteartifact', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved request to delete artifact from "+req.body.username+"\n"
			robot.messageRoom recipientid, dt
			remote_path = req.body.remote_path
			repos.delete_artifact remote_path, (error, stdout) ->
				if error
					msg.send error
					setTimeout (->index.passData error),1000
				else
					msg.send stdout
					setTimeout (->index.passData stdout),1000
		else
			dt="The request from "+req.body.username+" to delete artifact was rejected by "+req.body.approver
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
