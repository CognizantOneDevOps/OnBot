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
# lists all repositories of the configured user, creates public repos, deletes public repos
#
#Configuration:
# HUBOT_NAME
# HUBOT_GITHUB_API
# HUBOT_GITHUB_USER
# HUBOT_GITHUB_TOKEN
#
#COMMANDS:
# list my repos -> lists the names of the repositories of HUBOT_GITHUB_USER
# create repo <reponame> -> create an empty public repo with the given name
# create orgrepo <reponame> in <orgname> -> creates an empty repo with the given name inside given org
# delete repo <reponame> -> deletes the given github repo provided it is not inside an org
#
#Dependencies:
# "elasticSearch": "^0.9.2"
# "request": "2.81.0"
# "fs": "0.0.1-security"

request=require('request')
fs=require('fs')
readjson = require './readjson.js'
finaljson=" ";
index = require('./index')
generate_id = require('./mongoConnt')

git_url=process.env.HUBOT_GITHUB_API
git_user=process.env.HUBOT_GITHUB_USER
git_token=process.env.HUBOT_GITHUB_TOKEN

module.exports = (robot) ->
	robot.respond /list my repos/i, (msg) ->
		url=git_url+"/users/"+git_user+"/repos"
		options = {
		method: 'GET',
		url: url,
		headers: {'Authorization': 'token '+git_token,'user-agent': 'node-js'}};
		request.get options, (error, response, body) ->
			if(response.statusCode!=200)
				dt="Could not get repo list. Try again after some time"
				msg.send dt
				setTimeout (->index.passData dt),1000
			else
				dt = '*No.*\t\t\t*Repo Name*\n'
				for i in [0...JSON.parse(response.body).length]
					dt= dt + (i+1)+ "\t\t\t" + JSON.parse(response.body)[i].name + "\n"
				msg.send dt
				setTimeout (->index.passData dt),1000
	
	robot.respond /create repo (.*)/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			reponame=msg.match[1]
			if stdout.create_repo.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.create_repo.admin,podIp:process.env.MY_POD_IP,reponame:reponame,callback_id: 'githubrepo',msg:msg.toString()}
					data = {text: 'Approve Request',attachments: [{text: 'slack user '+payload.username+' requested to create repo named: '+payload.reponame,fallback: 'Yes or No?',callback_id: 'githubrepo',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approved', text: 'Approved', type: 'button', value: tckid,confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Approve','dismiss_text': 'Cancel'} },{ name: 'Rejected', text: 'Rejected',  type: 'button',  value: tckid,'style':'danger',confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Reject','dismiss_text': 'Cancel'}}]}]}
					robot.messageRoom stdout.create_repo.adminid, data
					msg.send  "Your request is Waiting for Approval from "+stdout.create_repo.admin;
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				url=git_url+"/user/repos"
				options = {
				method: 'POST',
				url: url,
				headers: {'Authorization': 'token '+git_token,'user-agent': 'request'},
				body: {'name': reponame,'auto_init': true},
				json: true};
				request.post options, (error, response, body) ->
					if(response.statusCode!=201)
						dt="Could not create new repository with name "+reponame+"\n"
						msg.send dt
						if(response.body.errors)
							dt=dt+response.body.errors[0].message
							msg.send response.body.errors[0].message
						setTimeout (->index.passData dt),1000
					else
						dt="Repository creation successful\n"+response.body.html_url
						msg.send dt
						setTimeout (->index.passData dt),1000
						message = msg.match[0]
						actionmsg = "github repository created"
						statusmsg = "Success"
						index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
	robot.router.post '/githubrepo', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved request for creating new repo: "+req.body.reponame+", requested by "+req.body.username+"\n"
			reponame=req.body.reponame
			url=git_url+"/user/repos"
			options = {
			method: 'POST',
			url: url,
			headers: {'Authorization': 'token '+git_token,'user-agent': 'request'},
			body: {'name': reponame,'auto_init': true},
			json: true};
			request.post options, (error, response, body) ->
				if(response.statusCode!=201)
					dt+="Could not create new repository with name "+reponame+"\n"
					if(response.body.errors)
						dt=dt+response.body.errors[0].message
					robot.messageRoom recipientid, dt
					setTimeout (->index.passData dt),1000
				else
					dt+="Repository creation successful\n"+response.body.html_url
					robot.messageRoom recipientid, dt
					setTimeout (->index.passData dt),1000
					message = "create repo "+reponame
					actionmsg = "github repository created"
					statusmsg = "Success"
					index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
		else
			dt="The request for creating new repo: "+req.body.reponame+" was rejected by "+req.body.approver+", requested by "+req.body.username
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
	
	robot.respond /create orgrepo (.*) in (.*)/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			reponame=msg.match[1]
			orgname=msg.match[2]
			if stdout.create_repo.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.create_repo.admin,podIp:process.env.MY_POD_IP,reponame:reponame,orgname:orgname,callback_id: 'githuborgrepo',msg:msg.toString()}
					data = {text: 'Approve Request',attachments: [{text: 'slack user '+payload.username+' requested to create repo named: '+payload.reponame+" inside org:"+payload.orgname,fallback: 'Yes or No?',callback_id: 'githuborgrepo',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approved', text: 'Approved', type: 'button', value: tckid,confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Approve','dismiss_text': 'Cancel'} },{ name: 'Rejected', text: 'Rejected',  type: 'button',  value: tckid,'style':'danger',confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Reject','dismiss_text': 'Cancel'}}]}]}
					robot.messageRoom stdout.create_repo.adminid, data
					msg.send  "Your request is Waiting for Approval from "+stdout.create_repo.admin;
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				url=git_url+"/user/repos"
				options = {
				method: 'POST',
				url: url,
				headers: {'Authorization': 'token '+git_token,'user-agent': 'request'},
				body: {'name': reponame,'auto_init': true},
				json: true};
				if(orgname!=null)
					options.url=git_url+"/orgs/"+orgname+"/repos"
				request.post options, (error, response, body) ->
					if(response.statusCode!=201)
						dt="Could not create new repository with name "+reponame
						msg.send "Could not create new repository with name "+reponame
						if(response.body.message)
							dt=dt+response.body.message
							msg.send response.body.message
						setTimeout (->index.passData dt),1000
					else
						dt="Repository creation successful\n"+response.body.html_url
						msg.send "Repository creation successful\n"+response.body.html_url
						setTimeout (->index.passData dt),1000
						message = msg.match[0]
						actionmsg = "github repository created"
						statusmsg = "Success"
						index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
	robot.router.post '/githuborgrepo', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved request for creating new repo: "+req.body.reponame+" inside org:"+req.body.orgname+", requested by "+req.body.username+"\n"
			reponame=req.body.reponame
			orgname=req.body.orgname
			url=git_url+"/user/repos"
			options = {
			method: 'POST',
			url: url,
			headers: {'Authorization': 'token '+git_token,'user-agent': 'request'},
			body: {'name': reponame,'auto_init': true},
			json: true};
			if(orgname!=null)
				options.url=git_url+"/orgs/"+orgname+"/repos"
			request.post options, (error, response, body) ->
				if(response.statusCode!=201)
					dt+="Could not create new repository with name "+reponame
					if(response.body.message)
						dt=dt+"\n"+response.body.message
					robot.messageRoom recipientid, dt
					setTimeout (->index.passData dt),1000
				else
					dt+="Repository creation successful\n"+response.body.html_url
					robot.messageRoom recipientid, dt
					setTimeout (->index.passData dt),1000
					message = "create orgrepo "+reponame+" in "+orgname
					actionmsg = "github repository created"
					statusmsg = "Success"
					index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
		else
			dt="The request for creating new repo: "+req.body.reponame+" inside org:"+req.body.orgname+" was rejected by "+req.body.approver+", requested by "+req.body.username
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
	
	robot.respond /delete repo (.*)/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			reponame=msg.match[1]
			if stdout.delete_repo.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.delete_repo.admin,podIp:process.env.MY_POD_IP,reponame:reponame,callback_id: 'deletegithubrepo',msg:msg.toString()}
					data = {text: 'Approve Request',attachments: [{text: 'slack user '+payload.username+' requested to delete repo named: '+payload.reponame,fallback: 'Yes or No?',callback_id: 'deletegithubrepo',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approved', text: 'Approved', type: 'button', value: tckid,confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Approve','dismiss_text': 'Cancel'} },{ name: 'Rejected', text: 'Rejected',  type: 'button',  value: tckid,'style':'danger',confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Reject','dismiss_text': 'Cancel'}}]}]}
					robot.messageRoom stdout.delete_repo.adminid, data
					msg.send  "Your request is Waiting for Approval from "+stdout.delete_repo.admin;
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				url=git_url+"/repos/"+git_user+"/"+reponame
				options = {
				method: 'DELETE',
				url: url,
				headers: {'Authorization': 'token '+git_token,'user-agent': 'request'},
				};
				request.delete options, (error, response, body) ->
					if(response.statusCode!=204)
						dt="Failed to delete repository "+reponame+"\n"+JSON.parse(response.body).message
						msg.send dt
						setTimeout (->index.passData dt),1000
					else
						dt=reponame+" : Deleted successfully"
						msg.send dt
						setTimeout (->index.passData dt),1000
						message = msg.match[0]
						actionmsg = "github repository deleted"
						statusmsg = "Success"
						index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
	robot.router.post '/deletegithubrepo', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved request for deleting repo: "+req.body.reponame+", requested by "+req.body.username+"\n"
			reponame=req.body.reponame
			url=git_url+"/repos/"+git_user+"/"+reponame
			options = {
			method: 'DELETE',
			url: url,
			headers: {'Authorization': 'token '+git_token,'user-agent': 'request'},
			};
			request.delete options, (error, response, body) ->
				if(response.statusCode!=204)
					dt+="Failed to delete repository "+reponame+"\n"+JSON.parse(response.body).message
					robot.messageRoom recipientid, dt
					setTimeout (->index.passData dt),1000
				else
					dt+=reponame+" : Deleted successfully"
					robot.messageRoom recipientid, dt
					setTimeout (->index.passData dt),1000
					message = "delete repo "+reponame
					actionmsg = "github repository deleted"
					statusmsg = "Success"
					index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
		else
			dt="The request for deleting repo: "+req.body.reponame+" was rejected by "+req.body.approver+", requested by "+req.body.username
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
