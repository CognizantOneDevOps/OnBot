#Description:
# lists all commands that this bot can perform
#
#Configuration:
# HUBOT_NAME
#
#COMMANDS:
# help -> lists all the commands that the bot can perform
#
#Dependencies:
# "elasticSearch": "^0.9.2"

index = require('./index')

module.exports = (robot) ->
	robot.respond /.*help.*/, (msg) ->
		console.log msg.message.user.activity
		dt="Here are the list of commands I can perform for you?<br>1) create repo <<*reponame*>> -> Create a repository<br>2) create orgrepo <<*reponame*>> in <<*orgname*>> -> Create a repository inside an org<br>3) list my repos -> List repository(ies)<br>4) create branch <<*new_branch_name*>> in <<*reponame*>> from <<*existing_branch_name*>> -> Create a branch<br>5) delete branch <<*branchname*>> from <<*reponame*>> -> Delete a branch<br>6) invite <<*invitee_gituser_name*>> to <<*reponame*>> -> Invite a user(collaborators) to a github repo<br>7) delete repo <<*reponame*>> -> Delete repository(ies)<br>8) list collaborators of <<*reponame*>> -> list collaborators of a repo<br>9) watch repo <<*reponame*>> -> Notify the user with commit Id and commit-author name whenever new commit occurs in the given repo<br>10) stop watching <<*reponame*>> -> will stop watching the repo for commits<br>P.S. preceed each command with @"+robot.name+" when you are in a channel/group<br>So what do you want me to do for you?"
		msg.send dt
		#robot.messageRoom msg.message.user.room.split('@')[0].split(':')[1]+msg.message.user.room.split(';messageid=')[1], dt
		#robot.messageRoom 'Susie', dt
		setTimeout ( ->index.passData dt),1000
