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
Creation and Deletion of a gitlab branch

Set of bot commands
1. create branch <branchname> for <projectID> from <oldbranchname>
2. delete branch <branchname> from <projectID>

Env to set:
1. HUBOT_GITLAB_API
2. HUBOT_GITLAB_USER
3. HUBOT_GITLAB_TOKEN
4. HUBOT_NAME
###

request=require('request')
fs=require('fs')
readjson = require ('./readjson.js')
index = require('./index')
generate_id = require('./mongoConnt')

botname = process.env.HUBOT_NAME
git_url=process.env.HUBOT_GITLAB_API
git_user=process.env.HUBOT_GITLAB_USER
git_token=process.env.HUBOT_GITLAB_TOKEN

module.exports = (robot) ->
	robot.respond /create branch (.*) for (.*) from (.*)/i, (msg) ->
		message = msg.match[0];
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			newbranch=msg.match[1]
			projectid=msg.match[2]
			oldbranch=msg.match[3]
			if stdout.gitlabcreatebranch.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					json={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.gitlabcreatebranch.admin,podIp:process.env.MY_POD_IP,newbranch:newbranch,projectid:projectid,oldbranch:oldbranch,msg:msg.toString(),callback_id:'gitlabcreatebranch'}
					data = {text: "Request from "+msg.message.user.name+" to create branch "+newbranch+" to project "+projectid+" from branch"+oldbranch ,attachments: [{text: 'click yes to approve ',fallback: 'Yes or No?',callback_id: 'gitlabcreatebranch',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: tckid,confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Approve','dismiss_text': 'Cancel'} },{ name: 'Reject', text: 'Reject',  type: 'button',  value: tckid,'style':'danger',confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Reject','dismiss_text': 'Cancel'}}]}]}
					console.log(data.attachments[0].actions[0]);
					robot.messageRoom stdout.gitlabcreatebranch.adminid, data
					msg.send  "You request is Waiting for Approval from "+stdout.gitlabcreatebranch.admin;
					dataToInsert = {ticketid: tckid, payload: json, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				newbranch=msg.match[1]
				projectid=msg.match[2]
				oldbranch=msg.match[3]
				url=git_url+"/projects/"+projectid+"/repository/branches"
				options = {
				method: 'POST',
				url: url,
				headers: {'PRIVATE-TOKEN': git_token},
				body: {"branch":newbranch,"ref":oldbranch},
				json: true};
				request.post options, (error, response, body) ->
					console.log response
					if(response.statusCode!=201)
						dt="Failed to create branch for projectId "+projectid+"\n"+response.body.message
						msg.send dt
						setTimeout (->index.passData dt),1000
					else
						dt="Branch created successfully"
						msg.send dt
						setTimeout (->index.passData dt),1000
						actionmsg = "Branch created successfully"
						statusmsg = 'Success';
						index.wallData botname, message, actionmsg, statusmsg;
	robot.router.post '/gitlabcreatebranch', (req, response) ->
		userid=req.body.userid
		if(req.body.action=='Approve')
			dt=req.body.approver+" approved creation of branch "+req.body.newbranch+", requested by "+req.body.username+"\n"
			newbranch=req.body.newbranch
			projectid=req.body.projectid
			oldbranch=req.body.oldbranch
			url=git_url+"/projects/"+projectid+"/repository/branches"
			options = {
			method: 'POST',
			url: url,
			headers: {'PRIVATE-TOKEN': git_token},
			body: {"branch":newbranch,"ref":oldbranch},
			json: true};
			request.post options, (error, response, body) ->
				console.log response
				if(response.statusCode!=201)
					dt="Failed to create branch for projectId "+projectid+"\n"+response.body.message
					robot.messageRoom userid, dt
					setTimeout (->index.passData dt),1000
				else
					dt="Branch created successfully"
					robot.messageRoom userid, dt
					setTimeout (->index.passData dt),1000
					message = 'create branch '+ newbranch + ' for '+ projectid + ' from ' + oldbranch ;
					actionmsg = 'Branch created successfully'
					statusmsg = 'Success';
					index.wallData botname, message, actionmsg, statusmsg;
		else
			dt="Branch Create request from "+req.body.username+" was rejected by "+req.body.approver
			robot.messageRoom userid, dt
			setTimeout (->index.passData dt),1000
	
	robot.respond /delete branch (.*) from (.*)/i, (msg) ->
		message = msg.match[0];
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			branch=msg.match[1]
			projectid=msg.match[2]
			if stdout.gitlabdeletebranch.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					json={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.room,approver:stdout.gitlabdeletebranch.admin,podIp:process.env.MY_POD_IP,branch:branch,projectid:projectid,msg:msg.toString(),callback_id:'gitlabdeletebranch'}
					data = {text: "Request from "+msg.message.user.name+" to delete branch "+branch+" from project "+projectid,attachments: [{text: 'click yes to approve ',fallback: 'Yes or No?',callback_id: 'gitlabdeletebranch',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: tckid,confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Approve','dismiss_text': 'Cancel'} },{ name: 'Reject', text: 'Reject',  type: 'button',  value: tckid,'style':'danger',confirm: {'title': 'Are you sure?','text': 'Are you sure?','ok_text': 'Reject','dismiss_text': 'Cancel'}}]}]}
					console.log(data.attachments[0].actions[0]);
					robot.messageRoom stdout.gitlabdeletebranch.adminid, data
					msg.send  "You request is Waiting for Approval from "+stdout.gitlabdeletebranch.admin;
					dataToInsert = {ticketid: tckid, payload: json, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				branch=msg.match[1]
				projectid=msg.match[2]
				url=git_url+"/projects/"+projectid+"/repository/branches/"+branch
				options = {
				method: 'DELETE',
				url: url,
				headers: {'PRIVATE-TOKEN': git_token}};
				request.delete options, (error, response, body) ->
					console.log response.statusCode
					if(response.statusCode!=204)
						dt="Failed to delete branch for projectId "+projectid+"\n"+JSON.parse(response.body).message
						msg.send dt
						setTimeout (->index.passData dt),1000
					else
						dt="Branch "+branch+" deleted successfully"
						msg.send dt
						setTimeout (->index.passData dt),1000
						actionmsg = "Branch deleted successfully"
						statusmsg = 'Success';
						index.wallData botname, message, actionmsg, statusmsg;
	robot.router.post '/gitlabdeletebranch', (req, response) ->
		userid=req.body.userid
		if(req.body.action=='Approve')
			dt=req.body.approver+" approved deletion og gitlab branch "+req.body.branch+", requested by "+req.body.username+"\n"
			branch=req.body.branch
			projectid=req.body.projectid
			url=git_url+"/projects/"+projectid+"/repository/branches/"+branch
			options = {
			method: 'DELETE',
			url: url,
			headers: {'PRIVATE-TOKEN': git_token}};
			request.delete options, (error, response, body) ->
				console.log response.statusCode
				if(response.statusCode!=204)
					dt="Failed to delete branch for projectId "+projectid+"\n"+JSON.parse(response.body).message
					robot.messageRoom userid, dt
					setTimeout (->index.passData dt),1000
				else
					dt="Branch "+branch+" deleted successfully"
					robot.messageRoom userid, dt
					setTimeout (->index.passData dt),1000
					message = 'delete branch '+ branch + ' from '+ branch;
					actionmsg = "Branch deleted successfully"
					statusmsg = 'Success';
					index.wallData botname, message, actionmsg, statusmsg;
		else
			dt="Branch Deletion request from "+req.body.username+" was rejected by "+req.body.approver
			robot.messageRoom userid, dt
			setTimeout (->index.passData dt),1000
