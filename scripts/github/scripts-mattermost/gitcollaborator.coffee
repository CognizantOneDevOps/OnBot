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
# lists all collaborators of a repo, invites collaborator
#
#Configuration:
# HUBOT_NAME
# HUBOT_GITHUB_API
# HUBOT_GITHUB_USER
# HUBOT_GITHUB_TOKEN
#
#COMMANDS:
# list collaborators of <reponame> -> lists all users who are contributing to the given github repo
# invite <git_user_name_of_invitee> to <reponame> -> sends invitation mail to the mentioned github user
# Example~
# invite testuser to testrepo
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
	cmdlistcols = new RegExp('@' + process.env.HUBOT_NAME + ' list collaborators of (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdlistcols
		(msg) ->
			reponame=msg.match[1]
			url=git_url+"/repos/"+git_user+"/"+reponame+"/collaborators"
			options = {
			method: 'GET',
			url: url,
			headers: {'Authorization': 'token '+git_token,'user-agent': 'node-js'}};
			request.get options, (error, response, body) ->
				if(response.statusCode!=200)
					dt=JSON.parse(response.body).message+"\nCould not get collaborator list. Check if reponame is correct."
					msg.send JSON.parse(response.body).message+"\nCould not get collaborator list. Check if reponame is correct."
					setTimeout (->index.passData dt),1000
				else
					dt = '*No.*\t\t*Collaborator Name*\t\t\t*Collaborator Info URL*\n'
					for i in [0...JSON.parse(response.body).length]
						dt= dt + (i+1)+"\t\t\t"+JSON.parse(response.body)[i].login+"\t\t\t"+JSON.parse(response.body)[i].url+"\n"
					msg.send dt
					setTimeout (->index.passData dt),1000
	)
	cmdinvite = new RegExp('@' + process.env.HUBOT_NAME + ' invite (.*) to (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match cmdinvite
		(msg) ->
			readjson.readworkflow_coffee (error,stdout,stderr) ->
				finaljson=stdout;
				invitee=msg.match[1]
				reponame=msg.match[2]
				if stdout.invite.workflowflag
					generate_id.getNextSequence (err,id) ->
						tckid=id
						console.log(tckid);
						payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.jid,podIp:process.env.MY_POD_IP,"callback_id":"githubinvite",invitee:invitee,reponame:reponame}
						data = {"channel": stdout.invite.admin,"text":"Request from "+payload.username+" to invite user","message":"Approve Request to invite user named "+invitee+" to repo "+reponame,attachments: [{text: 'click approve or reject',fallback: 'Yes or No?',callback_id: 'githubinvite',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button',"integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Approved",value: tckid}}},{ name: 'Reject', text: 'Reject', type: 'button', "integration": {"url": process.env.APPROVAL_APP_URL,"context": {"action": "Rejected",value: tckid}}}]}]}
						options = {
							url: process.env.MATTERMOST_INCOME_URL,
							method: "POST",
							header: {"Content-type":"application/json"},
							json: data
						}
						request.post options, (err,response,body) ->
							console.log response.body
						msg.send 'Your request is waiting for approval by '+stdout.invite.admin
						dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
						#Insert into Mongo with Payload
						generate_id.add_in_mongo dataToInsert
				else
					url=git_url+"/repos/"+git_user+"/"+reponame+"/collaborators/"+invitee
					options = {
					method: 'PUT',
					url: url,
					headers: {'Authorization': 'token '+git_token,'user-agent': 'node-js','Accept': 'application/vnd.github.swamp-thing-preview+json'}};
					request.put options, (error, response, body) ->
						if(response.statusCode!=201)
							dt=JSON.parse(response.body).message+". Could not send invite\nIncorrect username or reponame"
							msg.send JSON.parse(response.body).message+". Could not send invite\nIncorrect username or reponame"
							setTimeout (->index.passData dt),1000
						else
							dt="Invite sent to "+invitee+" :-)"
							msg.send "Invite sent to "+invitee+" :-)"
							setTimeout (->index.passData dt),1000
	)
	robot.router.post '/githubinvite', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			reponame=req.body.reponame
			invitee=req.body.invitee
			dt=req.body.approver+" approved inviting "+req.body.invitee+" to the repo: "+req.body.reponame+", requested by "+req.body.username+"\n"
			url=git_url+"/repos/"+git_user+"/"+reponame+"/collaborators/"+invitee
			options = {
			method: 'PUT',
			url: url,
			headers: {'Authorization': 'token '+git_token,'user-agent': 'node-js','Accept': 'application/vnd.github.swamp-thing-preview+json'}};
			request.put options, (error, response, body) ->
				if(response.statusCode!=201)
					dt+=JSON.parse(response.body).message+". Could not send invite\nIncorrect username or reponame"
					robot.messageRoom recipientid, dt
					setTimeout (->index.passData dt),1000
				else
					dt+="Invite sent to "+invitee+" :-)"
					robot.messageRoom recipientid, dt
					setTimeout (->index.passData dt),1000
		else
			dt="The request for inviting "+req.body.invitee+" to repo:"+req.body.reponame+" was rejected by "+req.body.approver+", requested by "+req.body.username
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
