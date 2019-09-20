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

post = (recipient, data) ->
	options = {method: "POST", url: recipient, json: data}
	request.post options, (error, response, body) ->
		console.log body

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
				dt = '*No.* *Repo Name*\r'
				for i in [0...JSON.parse(response.body).length]
					dt= dt + (i+1)+ ". " + JSON.parse(response.body)[i].name + "\r"
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
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.create_repo.admin,podIp:process.env.MY_POD_IP,reponame:reponame,callback_id: 'githubrepo',msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Request to create repo","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": "Create github repo named: "+payload.reponame,"activitySubtitle":"Requested by: "+payload.username,"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approved","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}
					
					#Post attachment to ms teams
					post stdout.create_repo.adminid, data
					msg.send  "Your request is Waiting for Approval from **"+stdout.create_repo.admin+"**"
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
			dt = {"text":"","title":""}
			dt.title=req.body.approver+" approved request for creating new repo: "+req.body.reponame+", requested by "+req.body.username+"\n"
			reponame=req.body.reponame
			url=git_url+"/user/repos"
			options = {
			method: 'POST',
			url: url,
			headers: {'Authorization': 'token '+git_token,'user-agent': 'request'},
			body: {'name': reponame,'auto_init': true},
			json: true};
			request.post options, (error, res, body) ->
				if(res.statusCode!=201)
					dt.text += "Could not create new repository with name "+reponame+"\n"
					if(res.body.errors)
						dt.text=dt.text+res.body.errors[0].message
					#post the response from bot to teams
					post recipientid, dt
					#response.send dt
					setTimeout (->index.passData dt),1000
				else
					dt.text+="Repository creation successful\n"+res.body.html_url
					#post the response from bot to teams
					post recipientid, dt
					setTimeout (->index.passData dt),1000
					message = "create repo "+reponame
					actionmsg = "github repository created"
					statusmsg = "Success"
					index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
		else
			dt = {"text":""}
			dt.text = "**The request for creating new repo: "+req.body.reponame+" was rejected by "+req.body.approver+", requested by "+req.body.username+"**"
			#post the response from bot to teams
			post recipientid, dt
			response.send dt
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
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.create_repo.admin,podIp:process.env.MY_POD_IP,reponame:reponame,orgname:orgname,callback_id: 'githuborgrepo',msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Request to create repo","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": "Create github repo named: "+payload.reponame+" inside org: "+payload.orgname,"activitySubtitle":"Requested by: "+payload.username,"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approved","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}
					post stdout.create_repo.adminid, data
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
			dt = {"text":"","title":""}
			dt.title = req.body.approver+" approved request for creating new repo: "+req.body.reponame+" inside org:"+req.body.orgname+", requested by "+req.body.username+"\n"
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
					dt.text += "Could not create new repository with name "+reponame
					if(response.body.message)
						dt.text=dt.text+"\n"+response.body.message
					post recipientid, dt
					setTimeout (->index.passData dt),1000
				else
					dt.text+="Repository creation successful\n"+response.body.html_url
					post recipientid, dt
					setTimeout (->index.passData dt),1000
					message = "create orgrepo "+reponame+" in "+orgname
					actionmsg = "github repository created"
					statusmsg = "Success"
					index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
		else
			dt = {"text":""}
			dt.text = "The request for creating new repo: "+req.body.reponame+" inside org:"+req.body.orgname+" was rejected by "+req.body.approver+", requested by "+req.body.username
			post recipientid, dt
			setTimeout (->index.passData dt),1000
	
	robot.respond /delete repo (.*)/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			reponame=msg.match[1]
			if stdout.delete_repo.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.delete_repo.admin,podIp:process.env.MY_POD_IP,reponame:reponame,callback_id: 'deletegithubrepo',msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Request to delete repo","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": "Delete github repo named: "+payload.reponame,"activitySubtitle":"Requested by: "+payload.username,"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approved","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}
					#Post attachment to ms teams
					post stdout.create_repo.adminid, data
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
			dt = {"text":"","title":""}
			dt.title = req.body.approver+" approved request for deleting repo: "+req.body.reponame+", requested by "+req.body.username+"\n"
			reponame=req.body.reponame
			url=git_url+"/repos/"+git_user+"/"+reponame
			options = {
			method: 'DELETE',
			url: url,
			headers: {'Authorization': 'token '+git_token,'user-agent': 'request'},
			};
			request.delete options, (error, response, body) ->
				if(response.statusCode!=204)
					dt.text+="Failed to delete repository "+reponame+"\n"+JSON.parse(response.body).message
					post recipientid, dt
					setTimeout (->index.passData dt),1000
				else
					dt.text+=reponame+" : Deleted successfully"
					post recipientid, dt
					setTimeout (->index.passData dt),1000
					message = "delete repo "+reponame
					actionmsg = "github repository deleted"
					statusmsg = "Success"
					index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
		else
			dt = {"text":""}
			dt.text = "**The request for deleting repo: "+req.body.reponame+" was rejected by "+req.body.approver+", requested by "+req.body.username+"**"
			post recipientid, dt
			setTimeout (->index.passData dt),1000