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
# creates and deletes branches inside a github repository
#
#Configuration:
# HUBOT_NAME
# HUBOT_GITHUB_API
# HUBOT_GITHUB_USER
# HUBOT_GITHUB_TOKEN
#
#COMMANDS:
# create branch <branchname> in <reponame> from <branchname_to_be_cloned_from> -> craetes a branch inside given reponame. branchname_to_be_cloned_from should
# also be inside the same repo where new branch is being created
# delete branch <baranchname> from <reponame> -> delete the given branch from the given repository
# Example~
# create newbranch in testrepo from master
# delete newbranch from testrepo
#
#Dependencies :
# "elasticSearch": "^0.9.2"
# "request": "2.81.0"
# "fs": "0.0.1-security"

request=require('request')
fs=require('fs')
index = require('./index')
readjson = require './readjson.js'
finaljson=" ";
generate_id = require('./mongoConnt')

git_url=process.env.HUBOT_GITHUB_API
git_user=process.env.HUBOT_GITHUB_USER
git_token=process.env.HUBOT_GITHUB_TOKEN

module.exports = (robot) ->
	cmdcreatebranch = new RegExp('@' + process.env.HUBOT_NAME + ' create branch (.*) in (.*) from (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdcreatebranch
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				finaljson=stdout;
				newbranch=msg.match[1]
				reponame=msg.match[2]
				oldbranch=msg.match[3]
				if stdout.create_branch.workflowflag
					generate_id.getNextSequence (err,id) ->
						tckid=id
						console.log(tckid);
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.jid,podIp:process.env.MY_POD_IP,"callback_id":"creategithubbranch",newbranch:newbranch,reponame:reponame,oldbranch:oldbranch}
						data = {"channel": stdout.create_branch.admin,"text":"Request from "+payload.username+" to create github branch","message":"Approve Request to create new branch named "+newbranch+" inside repo "+reponame+" from "+oldbranch,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'creategithubbranch',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval by '+stdout.create_branch.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						#Insert into Mongo with Payload
						generate_id.add_in_mongo dataToInsert
				else
					url=git_url+"/repos/"+git_user+"/"+reponame+"/commits/"+oldbranch
					options = {
					method: 'GET',
					url: url,
					headers: {'Authorization': 'token '+git_token,'user-agent': 'node-js'}};
					request.get options, (error, response, body) ->
						if(response.statusCode==404)
							dt=JSON.parse(response.body).message+"\nIncorrect Repository or branchname\n"+url
							msg.send JSON.parse(response.body).message+"\nIncorrect Repository or branchname\n"+url
							setTimeout (->index.passData dt),1000
						options.method='POST'
						options.url=git_url+"/repos/"+git_user+"/"+reponame+"/git/refs"
						options.body={
							"ref": "refs/heads/"+newbranch,
							"sha": JSON.parse(response.body).sha}
						options.json=true
						if(JSON.parse(response.body).sha)
							request.post options, (error, response, body) ->
								if(response.statusCode!=201)
									dt="Failed to create branch "+newbranch+" inside "+reponame+"\n"+response.body.message
									msg.send dt
									setTimeout (->index.passData dt),1000
								else
									dt="Branch "+newbranch+" created inside "+reponame+"\nhttps://github.com/"+git_user+"/"+reponame+"/tree/"+newbranch
									msg.send dt
									message = msg.match[0]
									actionmsg = "github branch created"
									statusmsg = "Success"
									index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
									setTimeout (->index.passData dt),1000
	
	)
	robot.router.post '/creategithubbranch', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved branch "+req.body.newbranch+" creation request from "+req.body.username+"\n"
			newbranch=req.body.newbranch
			reponame=req.body.reponame
			oldbranch=req.body.oldbranch
			url=git_url+"/repos/"+git_user+"/"+reponame+"/commits/"+oldbranch
			options = {
			method: 'GET',
			url: url,
			headers: {'Authorization': 'token '+git_token,'user-agent': 'node-js'}};
			request.get options, (error, response, body) ->
				if(response.statusCode==404)
					dt+=JSON.parse(response.body).message+"\nIncorrect Repository or branchname\n"+url
					robot.messageRoom recipientid, dt
					setTimeout (->index.passData dt),1000
				options.method='POST'
				options.url=git_url+"/repos/"+git_user+"/"+reponame+"/git/refs"
				options.body={
					"ref": "refs/heads/"+newbranch,
					"sha": JSON.parse(response.body).sha}
				options.json=true
				if(JSON.parse(response.body).sha)
					request.post options, (error, response, body) ->
						if(response.statusCode!=201)
							dt+="Failed to create branch "+newbranch+" inside "+reponame+"\n"+response.body.message
							robot.messageRoom recipientid, dt
							setTimeout (->index.passData dt),1000
						else
							dt+="Branch "+newbranch+" created inside "+reponame+"\nhttps://github.com/"+git_user+"/"+reponame+"/tree/"+newbranch
							robot.messageRoom recipientid, dt
							setTimeout (->index.passData dt),1000
							message = "create branch "+newbranch+" in "+reponame+" from "+oldbranch
							actionmsg = "github branch created"
							statusmsg = "Success"
							index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
		else
			dt="The branch creation request from "+req.body.username+" was rejected by "+req.body.approver
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
	
	cmddeletebranch = new RegExp('@' + process.env.HUBOT_NAME + ' delete branch (.*) from (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmddeletebranch
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				finaljson=stdout;
				reponame=msg.match[2]
				branchname=msg.match[1]
				if stdout.delete_branch.workflowflag
					generate_id.getNextSequence (err,id) ->
						tckid=id
						console.log(tckid);
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.jid,podIp:process.env.MY_POD_IP,"callback_id":"deletegithubbranch",branchname:branchname,reponame:reponame}
						data = {"channel": stdout.delete_branch.admin,"text":"Request from "+payload.username+" to delete github branch","message":"Approve Request to delete branch named "+branchname+" from repo "+reponame,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'deletegithubbranch',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval by '+stdout.delete_branch.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						#Insert into Mongo with Payload
						generate_id.add_in_mongo dataToInsert
				else
					url=git_url+"/repos/"+git_user+"/"+reponame+"/git/refs/heads/"+branchname
					options = {
					method: 'DELETE',
					url: url,
					headers: {'Authorization': 'token '+git_token,'user-agent': 'node-js'}};
					request.delete options, (error, response, body) ->
						if(response.statusCode!=204)
							dt="Couldn't delete branch "+branchname+"\n"+JSON.parse(response.body).message
							robot.messageRoom recipientid, dt
							setTimeout (->index.passData dt),1000
						else
							dt="Deleted branch "+branchname+" successfully"
							robot.messageRoom recipientid, dt
							message = msg.match[0]
							actionmsg = "github branch deleted"
							statusmsg = "Success"
							index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
							setTimeout (->index.passData dt),1000
	)
	
	robot.router.post '/deletegithubbranch', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved branch "+req.body.branchname+" deletion request from "+req.body.username+"\n"
			reponame=req.body.reponame
			branchname=req.body.branchname
			url=git_url+"/repos/"+git_user+"/"+reponame+"/git/refs/heads/"+branchname
			options = {
			method: 'DELETE',
			url: url,
			headers: {'Authorization': 'token '+git_token,'user-agent': 'node-js'}};
			request.delete options, (error, response, body) ->
				if(response.statusCode!=204)
					dt+="Couldn't delete branch "+branchname+"\n"+JSON.parse(response.body).message
					robot.messageRoom recipientid, dt
					setTimeout (->index.passData dt),1000
				else
					dt+="Deleted branch "+branchname+" successfully"
					robot.messageRoom recipientid, dt
					setTimeout (->index.passData dt),1000
					message = "delete branch "+branchname+" from "+reponame
					actionmsg = "github branch deleted"
					statusmsg = "Success"
					index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
		else
			dt="The deletion request for branch "+req.body.branchname+" from "+req.body.username+" was rejected by "+req.body.approver
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
