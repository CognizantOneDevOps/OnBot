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

###
Coffee script used for:
Adding,removing and listing a user 

Set of bot commands
1. add user <userID> to <projectID>
2. remove user <userID> from <projectID>
3. list members of <projectID>

Env to set:
1. HUBOT_GITLAB_API
2. HUBOT_GITLAB_USER
3. HUBOT_GITLAB_TOKEN
4. HUBOT_NAME
###

request=require('request')
readjson = require ('./readjson.js')
index = require('./index')
generate_id = require('./mongoConnt')

botname = process.env.HUBOT_NAME
git_url=process.env.HUBOT_GITLAB_API
git_user=process.env.HUBOT_GITLAB_USER
git_token=process.env.HUBOT_GITLAB_TOKEN

module.exports = (robot) ->
	robot.respond /list members of (.*)/i, (msg) ->
		projectid=msg.match[1]
		url=git_url+"/projects/"+projectid+"/members"
		options = {
		method: 'GET',
		url: url,
		headers: {'PRIVATE-TOKEN': git_token}};
		request.get options, (error, response, body) ->
			console.log response.statusCode
			if(response.statusCode!=200)
				msg.send "Failed to get list for projectId "+projectid+"\n"+JSON.parse(response.body).message
			else
				dt=''
				for i in [0...JSON.parse(response.body).length]
					dt+=JSON.parse(response.body)[i].name+" [user id: "+JSON.parse(response.body)[i].id+"]\n"
				msg.send dt
	
	robot.respond /add user (.*) to (.*)/i, (msg) ->
		message = msg.match[0];
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			userids=msg.match[1]
			projectid=msg.match[2]
			if stdout.gitlabadduser.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					json={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.gitlabadduser.admin,podIp:process.env.MY_POD_IP,userids:userids,projectid:projectid,userxml:msg.match[2],msg:msg.toString(),callback_id:'gitlabadduser'}
					data = {text: "Request from "+msg.message.user.name+" to add user "+userids+" to project "+projectid ,attachments: [{text: 'click yes to approve ',fallback: 'Yes or No?',callback_id: 'gitlabadduser',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: tckid,confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Approve','dismiss_text': 'Cancel'} },{ name: 'Reject', text: 'Reject',  type: 'button',  value: tckid,'style':'danger',confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Reject','dismiss_text': 'Cancel'}}]}]}
					console.log(data.attachments[0].actions[0]);
					robot.messageRoom stdout.gitlabadduser.adminid, data
					msg.send  "You request is Waiting for Approval from "+stdout.gitlabadduser.admin;
					dataToInsert = {ticketid: tckid, payload: json, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				userids=msg.match[1]
				projectid=msg.match[2]
				url=git_url+"/projects/"+projectid+"/members"
				options = {
				method: 'POST',
				url: url,
				headers: {'PRIVATE-TOKEN': git_token},
				body: {'user_id':userids,'access_level':30},
				json:true};
				request.post options, (error, response, body) ->
					console.log response.statusCode
					if(response.statusCode!=201)
						dt="Failed to add user for projectId "+projectid+"\n"+response.body.message
						msg.send dt
						setTimeout (->index.passData dt),1000
					else
						dt="Added user with id "+userids+" successfully"
						msg.send dt
						setTimeout (->index.passData dt),1000
						actionmsg = "User added successfully"
						statusmsg = 'Success';
						index.wallData botname, message, actionmsg, statusmsg;
	robot.router.post '/gitlabadduser', (req, response) ->
		userid=req.body.userid
		if(req.body.action=='Approve')
			dt=req.body.approver+" approved addition of gitlab user "+req.body.userids+", requested by "+req.body.username+"\n"
			userids=req.body.userids
			projectid=req.body.projectid
			url=git_url+"/projects/"+projectid+"/members"
			options = {
			method: 'POST',
			url: url,
			headers: {'PRIVATE-TOKEN': git_token},
			body: {'user_id':userids,'access_level':30},
			json:true};
			request.post options, (error, response, body) ->
				console.log response.statusCode
				if(response.statusCode!=201)
					dt="Failed to add user for projectId "+projectid+"\n"+response.body.message
					robot.messageRoom userid, dt
					setTimeout (->index.passData dt),1000
				else
					dt="Added user with id "+userids+" successfully"
					robot.messageRoom userid, dt
					setTimeout (->index.passData dt),1000
					message = 'Add user '+ userids + ' to '+ projectid;
					actionmsg = "User added successfully"
					statusmsg = 'Success';
					index.wallData botname, message, actionmsg, statusmsg;
		else
			dt="Add Gitlab user request from "+req.body.username+" was rejected by "+req.body.approver
			robot.messageRoom userid, dt
			setTimeout (->index.passData dt),1000
	
	robot.respond /remove user (.*) from (.*)/i, (msg) ->
		message = msg.match[0];
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			userids=msg.match[1]
			projectid=msg.match[2]
			if stdout.gitlabdeleteuser.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					json={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.gitlabdeleteuser.admin,podIp:process.env.MY_POD_IP,userids:userids,projectid:projectid,userxml:msg.match[2],msg:msg.toString(),callback_id:'gitlabdeleteuser'}
					data = {text: "Request from "+msg.message.user.name+" to remove user "+userids+" to project "+projectid ,attachments: [{text: 'click yes to approve ',fallback: 'Yes or No?',callback_id: 'gitlabdeleteuser',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: tckid,confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Approve','dismiss_text': 'Cancel'} },{ name: 'Reject', text: 'Reject',  type: 'button',  value: tckid,'style':'danger',confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Reject','dismiss_text': 'Cancel'}}]}]}
					console.log(data.attachments[0].actions[0]);
					robot.messageRoom stdout.gitlabdeleteuser.adminid, data
					msg.send  "You request is Waiting for Approval from "+stdout.gitlabdeleteuser.admin;
					dataToInsert = {ticketid: tckid, payload: json, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				userids=msg.match[1]
				projectid=msg.match[2]
				url=git_url+"/projects/"+projectid+"/members/"+userids
				options = {
				method: 'DELETE',
				url: url,
				headers: {'PRIVATE-TOKEN': git_token}};
				request.delete options, (error, response, body) ->
					console.log response.statusCode
					if(response.statusCode!=204)
						dt="Failed to remove user for projectId "+projectid+"\n"+JSON.parse(response.body).message
						msg.send dt
						setTimeout (->index.passData dt),1000
					else
						dt="Removed user with id "+userids+" successfully"
						msg.send dt
						setTimeout (->index.passData dt),1000
						actionmsg = "User removed successfully"
						statusmsg = 'Success';
						index.wallData botname, message, actionmsg, statusmsg;
	robot.router.post '/gitlabdeleteuser', (req, response) ->
		userid = req.body.userid
		if(req.body.action=='Approve')
			dt=req.body.approver+" approved addition of gitlab user "+req.body.userids+", requested by "+req.body.username+"\n"
			userids=req.body.userids
			projectid=req.body.projectid
			url=git_url+"/projects/"+projectid+"/members/"+userids
			options = {
			method: 'DELETE',
			url: url,
			headers: {'PRIVATE-TOKEN': git_token}};
			request.delete options, (error, response, body) ->
				console.log response.statusCode
				if(response.statusCode!=204)
					dt="Failed to remove user for projectId "+projectid+"\n"+JSON.parse(response.body).message
					robot.messageRoom userid, dt
					setTimeout (->index.passData dt),1000
				else
					dt="Removed user with id "+userids+" successfully"
					robot.messageRoom userid, dt
					setTimeout (->index.passData dt),1000
					message = 'remove user '+ userids + ' from '+ projectid;
					actionmsg = "User removed successfully"
					statusmsg = 'Success';
					index.wallData botname, message, actionmsg, statusmsg;
		else
			dt="Remove Gitlab user request from "+req.body.username+" was rejected by "+req.body.approver
			robot.messageRoom userid, dt
			setTimeout (->index.passData dt),1000
