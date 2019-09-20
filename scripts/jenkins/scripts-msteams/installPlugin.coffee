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
#Description:
# installs the given plugins to jenkins
#
#Configuration:
# HUBOT_NAME
# HUBOT_JENKINS_URL
# HUBOT_JENKINS_USER
# HUBOT_JENKINS_PASSWORD
# HUBOT_JENKINS_API_TOKEN
# HUBOT_JENKINS_VERSION
#
#COMMANDS:
# install <plugin1> <plugin2>... in jenkins -> install the given plugins to jenkins
# Example~
# install ccm msbuild mstest in jenkins
# (The above command will install ccm, msbuld and mstest plugin in jenkins)
#
#Depencencies:
# "request":"2.81.0"
# "elasticSearch": "^0.9.2"

request = require('request')
index = require('./index')
readjson = require './readjson.js'
finaljson=" ";
generate_id = require('./mongoConnt');
crumb = require('./jenkinscrumb.js')

jenkins_url=process.env.HUBOT_JENKINS_URL
jenkins_user=process.env.HUBOT_JENKINS_USER
jenkins_pass=process.env.HUBOT_JENKINS_PASSWORD
jenkins_api=process.env.HUBOT_JENKINS_API_TOKEN
jenkins_version=process.env.HUBOT_JENKINS_VERSION

crumbvalue = ''
options = {
url: '',
auth: {
'user': jenkins_user,
'pass': jenkins_api
},
method: 'POST',
headers:{}};
if jenkins_version >= 2.0
	crumb.crumb (stderr, stdout) ->
		console.log stdout
		if(stdout)
			crumbvalue=stdout

post = (recipient, data) ->
	options = {method: "POST", url: recipient, json: data}
	request.post options, (error, response, body) ->
		console.log body

module.exports = (robot) ->
	robot.respond /install (.+) in jenkins/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			userplugin=[]
			userplugin=msg.match[1].split(' ')
			if stdout.install_plugin.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					console.log(msg.toString())
					
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:process.env.CURRENT_CHANNEL,approver:stdout.install_plugin.admin,podIp:process.env.MY_POD_IP,userplugin:userplugin,"callback_id":"installplugin",msg:msg.toString()}
					data = {"type": "MessageCard","context": "http://schema.org/extensions","summary": "Requested to install the plugins in jenkins","themeColor": "81CAF7","sections":[{"startGroup": true,"title": "**Approval Required!**","activityTitle": 'user '+payload.username+' requested to install the following plugins in jenkins:\n'+payload.userplugin,"facts": []},{"potentialAction": [{"@type": "HttpPOST","name": "Approve","target": process.env.APPROVAL_APP_URL+"/Approved","body": "{\"tckid\": \""+tckid+"\" }", "bodyContentType":"application/x-www-form-urlencoded"},{"@type": "HttpPOST","name": "Deny","target": process.env.APPROVAL_APP_URL+"/Rejected","body": "{\"tckid\": \""+tckid+"\" }","bodyContentType":"application/x-www-form-urlencoded"}]}]}
					#Post attachment to ms teams
					post stdout.install_plugin.adminid, data
					msg.send 'Your request is waiting for approval by '+stdout.install_plugin.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				pluginString=[]
				plugins=[]
				flag=0
				pluginString=msg.match[1].split(' ')
				url=jenkins_url+"/pluginManager/installNecessaryPlugins"
				pluginData="<jenkins>"
				for i in [0...pluginString.length]
					pluginData=pluginData+"<install plugin=\""+pluginString[i]+"@latest\" /></jenkins>"
					options = {
					auth: {
					'user': jenkins_user,
					'pass': jenkins_pass
					},
					method: 'POST',
					url: url,
					headers: {"Content-Type": "text/xml"},
					body: pluginData};
					if jenkins_version >= 2.0
						options.headers["Jenkins-Crumb"]=crumbvalue
						options.auth.pass = jenkins_api
					request.post options, (error, response, body) ->
						if(response.statusCode!=302)
							dt="Error in installing"
							msg.send dt
							setTimeout (->index.passData dt),1000
						else
							setTimeout ( -> getInstallations()),1000
					pluginData="<jenkins>"

				getInstallations = () ->
					options.url=jenkins_url+"/pluginManager/api/json?depth=1&xpath=/*/*/shortName|/*/*/version&wrapper=plugins"
					options.headers={"Content-Type": "text/json"}
					if jenkins_version >= 2.0
						options.headers["Jenkins-Crumb"]=crumbvalue
						options.auth.pass = jenkins_api
					request.post options, (error, response, body) ->
						plugins=JSON.parse(body).plugins
				setTimeout ( -> check plugins),2000
				check = (plugins) ->
					if(plugins.length!=0)
						for i in [0...pluginString.length]
							for j in [0...plugins.length]
								console.log plugins[j].shortName
								if(pluginString[i]==plugins[j].shortName)
									dt=pluginString[i]+": Installed successfully"
									msg.send dt
									setTimeout (->index.passData dt),1000
									message = msg.match[0]
									actionmsg = "jenkins plugin installed"
									statusmsg = "Success"
									index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
									flag=1
									break
							if(flag==0)
								dt=pluginString[i]+": Error in installation. Verify the pluginID and try again"
								msg.send dt
								setTimeout (->index.passData dt),1000
							flag=0
	#the following code handles the approval flow of the command
	robot.router.post '/installplugin', (req, response) ->
		console.log(' INSIDE installplugin')
		recipientid=req.body.userid
		dt = {"text":"","title":""}
		if(req.body.action=='Approved')
			dt.title=req.body.approver+" approved installation of plugins "+req.body.userplugin+", requested by "+req.body.username+"\n"
			post recipientid, dt
			index.passData dt
			pluginString=[]
			plugins=[]
			flag=0
			pluginString=req.body.userplugin
			url=jenkins_url+"/pluginManager/installNecessaryPlugins"
			pluginData="<jenkins>"
			for i in [0...pluginString.length]
				pluginData=pluginData+"<install plugin=\""+pluginString[i]+"@latest\" /></jenkins>"
				options = {
				auth: {
				'user': jenkins_user,
				'pass': jenkins_pass
				},
				method: 'POST',
				url: url,
				headers: {"Content-Type": "text/xml"},
				body: pluginData};
				if jenkins_version >= 2.0
					options.headers["Jenkins-Crumb"]=crumbvalue
				request.post options, (error, response, body) ->
					if(response.statusCode!=302)
						dt.text="error in installing"
						post recipientid, dt
						setTimeout (->index.passData dt),1000
					else
						setTimeout ( -> getInstallations()),1000
				pluginData="<jenkins>"

			getInstallations = () ->
				options.url=jenkins_url+"/pluginManager/api/json?depth=1&xpath=/*/*/shortName|/*/*/version&wrapper=plugins"
				options.headers={"Content-Type": "text/json"}
				if jenkins_version >= 2.0
					options.headers["Jenkins-Crumb"]=crumbvalue
				request.post options, (error, response, body) ->
					plugins=JSON.parse(body).plugins
			setTimeout ( -> check plugins),2000
			check = (plugins) ->
				if(plugins.length!=0)
					for i in [0...pluginString.length]
						for j in [0...plugins.length]
							console.log plugins[j].shortName
							if(pluginString[i]==plugins[j].shortName)
								dt.text=pluginString[i]+": installed successfully"
								post recipientid, dt
								setTimeout (->index.passData dt),1000
								message = "install "+pluginString+"in jenkins"
								actionmsg = "jenkins plugin installed"
								statusmsg = "Success"
								index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
								flag=1
								break
						if(flag==0)
							dt.text=pluginString[i]+": error in installation. verify the pluginid and try again"
							post recipientid, dt
							setTimeout (->index.passData dt),1000
						flag=0
		else
			dt.title="the jenkins plugin installation request from "+req.body.username+" was rejected by "+req.body.approver
			post recipientid, dt
			setTimeout (->index.passData dt),1000
