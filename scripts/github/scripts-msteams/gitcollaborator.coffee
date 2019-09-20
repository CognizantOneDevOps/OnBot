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

post = (recipient, data) ->
	options = {method: "POST", url: recipient, json: data}
	request.post options, (error, response, body) ->
		console.log body

module.exports = (robot) ->
	robot.respond /list collaborators of (.*)/i, (msg) ->
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
				dt = '*Collaborator Name* \r'
				for i in [0...JSON.parse(response.body).length]
					dt += (i+1) + "." + "\t["+JSON.parse(response.body)[i].login+"]("+JSON.parse(response.body)[i].url+")"
				msg.send dt
				setTimeout (->index.passData dt),1000
	
	robot.respond /invite (.*) to (.*)/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			invitee=msg.match[1]
			reponame=msg.match[2]
			if stdout.invite.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.invite.admin,podIp:process.env.MY_POD_IP,invitee:invitee,reponame:reponame,callback_id: 'githubinvite',msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Request to create repo","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": "Invite user named: "+payload.invitee+" to repo: "+payload.reponame,"activitySubtitle":"Requested by: "+payload.username,"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approved","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}
					post stdout.invite.adminid, data
					msg.send  "Your request is Waiting for Approval from "+stdout.invite.admin;
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				url=git_url+"/repos/"+git_user+"/"+reponame+"/collaborators/"+invitee
				#url=git_url+"/ugly-duckling/"+reponame+"/collaborators/"+invitee
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
	robot.router.post '/githubinvite', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt = {"text":"","title":""}
			reponame=req.body.reponame
			invitee=req.body.invitee
			dt.title=req.body.approver+" approved inviting "+req.body.invitee+" to the repo: "+req.body.reponame+", requested by "+req.body.username+"\n"
			url=git_url+"/repos/"+git_user+"/"+reponame+"/collaborators/"+invitee
			#url=git_url+"/ugly-duckling/"+reponame+"/collaborators/"+invitee
			options = {
			method: 'PUT',
			url: url,
			headers: {'Authorization': 'token '+git_token,'user-agent': 'node-js','Accept': 'application/vnd.github.swamp-thing-preview+json'}};
			request.put options, (error, response, body) ->
				if(response.statusCode!=201)
					dt.text+=JSON.parse(response.body).message+". Could not send invite\nIncorrect username or reponame"
					post recipientid, dt
					setTimeout (->index.passData dt),1000
				else
					dt.text+="Invite sent to "+invitee+" :-)"
					post recipientid, dt
					setTimeout (->index.passData dt),1000
		else
			dt = {"text":""}
			dt.text="**The request for inviting "+req.body.invitee+" to repo:"+req.body.reponame+" was rejected by "+req.body.approver+", requested by "+req.body.username+"**"
			post recipientid, dt
			setTimeout (->index.passData dt),1000