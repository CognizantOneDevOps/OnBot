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

post = (recipient, data) ->
	options = {method: "POST", url: recipient, json: data}
	request.post options, (error, response, body) ->
		console.log body

module.exports = (robot) ->
	robot.respond /create branch (.*) in (.*) from (.*)/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			newbranch=msg.match[1]
			reponame=msg.match[2]
			oldbranch=msg.match[3]
			if stdout.create_branch.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.create_branch.admin,podIp:process.env.MY_POD_IP,newbranch:newbranch,reponame:reponame,oldbranch:oldbranch,callback_id: 'creategithubbranch',msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Request to create repo","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": "Create branch named: "+payload.newbranch+" from branch: "+payload.oldbranch+" inside repo: "+payload.reponame,"activitySubtitle":"Requested by: "+payload.username,"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approved","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}
					post stdout.create_branch.adminid, data
					msg.send  "Your request is Waiting for Approval from "+stdout.create_branch.admin;
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
	
	robot.router.post '/creategithubbranch', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt = {"text":"","title":""}
			dt.title=req.body.approver+" approved branch "+req.body.newbranch+" creation request from "+req.body.username+"\n"
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
					dt.text+=JSON.parse(response.body).message+"\nIncorrect Repository or branchname\n"+url
					post recipientid, dt
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
							dt.text+="Failed to create branch "+newbranch+" inside "+reponame+"\n"+response.body.message
							post recipientid, dt
							setTimeout (->index.passData dt),1000
						else
							dt.text+="Branch "+newbranch+" created inside "+reponame+"\nhttps://github.com/"+git_user+"/"+reponame+"/tree/"+newbranch
							post recipientid, dt
							setTimeout (->index.passData dt),1000
							message = "create branch "+newbranch+" in "+reponame+" from "+oldbranch
							actionmsg = "github branch created"
							statusmsg = "Success"
							index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
		else
			dt = {"text":""}
			dt.text="**The branch creation request from "+req.body.username+" was rejected by "+req.body.approver+"**"
			post recipientid, dt
			setTimeout (->index.passData dt),1000
	
	robot.respond /delete branch (.*) from (.*)/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			reponame=msg.match[2]
			branchname=msg.match[1]
			if stdout.delete_branch.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.delete_branch.admin,podIp:process.env.MY_POD_IP,branchname:branchname,reponame:reponame,callback_id: 'deletegithubbranch',msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Request to create repo","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": "Delete branch named: "+payload.branchname+" from repo: "+payload.reponame,"activitySubtitle":"Requested by: "+payload.username,"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approved","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}
					post stdout.delete_branch.adminid, data
					msg.send  "Your request is Waiting for Approval from "+stdout.delete_branch.admin;
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
						msg.send dt
						setTimeout (->index.passData dt),1000
					else
						dt="Deleted branch "+branchname+" successfully"
						msg.send dt
						message = msg.match[0]
						actionmsg = "github branch deleted"
						statusmsg = "Success"
						index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
						setTimeout (->index.passData dt),1000
	
	robot.router.post '/deletegithubbranch', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt = {"text":"","title":""}
			dt.title=req.body.approver+" approved branch "+req.body.branchname+" deletion request from "+req.body.username+"\n"
			reponame=req.body.reponame
			branchname=req.body.branchname
			url=git_url+"/repos/"+git_user+"/"+reponame+"/git/refs/heads/"+branchname
			options = {
			method: 'DELETE',
			url: url,
			headers: {'Authorization': 'token '+git_token,'user-agent': 'node-js'}};
			request.delete options, (error, response, body) ->
				if(response.statusCode!=204)
					dt.text+="Couldn't delete branch "+branchname+"\n"+JSON.parse(response.body).message
					post recipientid, dt
					setTimeout (->index.passData dt),1000
				else
					dt.text+="Deleted branch "+branchname+" successfully"
					post recipientid, dt
					setTimeout (->index.passData dt),1000
					message = "delete branch "+branchname+" from "+reponame
					actionmsg = "github branch deleted"
					statusmsg = "Success"
					index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
		else
			dt = {"text":""}
			dt.text="**The deletion request for branch "+req.body.branchname+" from "+req.body.username+" was rejected by "+req.body.approver+"**"
			post recipientid, dt
			setTimeout (->index.passData dt),1000
