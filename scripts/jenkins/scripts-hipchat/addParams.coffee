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
# Adds a new param by downloading the config.xml file of a jenkins job,
# modifying the config.xml and uploading it
#
#Configuration:
# HUBOT_JENKINS_URL
# HUBOT_JENKINS_USER
# HUBOT_JENKINS_PASSWORD
# HUBOT_JENKINS_API_TOKEN
# HUBOT_JENKINS_VERSION
#
#COMMANDS:
#give <jobname> config -> downloads the config.xml file and saves it as <jobname>_config.xml inside 'scripts' folder
#upload <jobname> config -> uploads <jobname>_config.xml from scripts folder as config.xml for <jobname>
#
#Dependencies:
# "elasticSearch": "^0.9.2"
# "request": "2.81.0"

request = require('request')
fs=require('fs')
index = require('./index')
crumb = require('./jenkinscrumb.js')

jenkins_url=process.env.HUBOT_JENKINS_URL
jenkins_user=process.env.HUBOT_JENKINS_USER
jenkins_pass=process.env.HUBOT_JENKINS_PASSWORD
jenkins_api=process.env.HUBOT_JENKINS_API_TOKEN
jenkins_version=process.env.HUBOT_JENKINS_VERSION

crumbvalue = ''
if jenkins_version >= 2.0
	crumb.crumb (stderr, stdout) ->
		console.log stdout
		if(stdout)
			crumbvalue=stdout

module.exports = (robot) ->
	robot.respond /give (.*) config/i, (msg) ->
		jobname=msg.match[1]
		filepath="scripts/"+jobname+"_config.xml"
		url=jenkins_url+"/job/"+jobname+"/config.xml"
		options = {
		url: url,
		auth: {
			'user': jenkins_user,
			'pass': jenkins_pass
		},
		method: 'GET',
		headers: {"Content-Type":"text/xml"} };
		if jenkins_version >= 2.0
			options.headers["Jenkins-Crumb"]=crumbvalue
			options.auth.pass = jenkins_api
		request.get options, (error, response, body) ->
			fs.writeFile filepath, body, (err) ->
				if(err)
					dt="Could not get config for "+jobname
					msg.send dt
					setTimeout (->index.passData dt),1000
				else
					dt="Config file retreived successfully as "+jobname+"_config.xml"
					msg.send dt
					setTimeout (->index.passData dt),1000
	
	robot.respond /upload (.*) config/i, (msg) ->
		jobname=msg.match[1]
		url=jenkins_url+"/job/"+jobname+"/config.xml"
		fs.readFile './scripts/'+jobname+'_config.xml', 'utf8', (err, fileData) ->
			if(err)
				dt="Error in reading XML: " +err
				msg.send dt
				setTimeout (->index.passData dt),1000
			else
				options = {
				url: url,
				auth: {
					'user': jenkins_user,
					'pass': jenkins_pass
				},
				method: 'POST',
				headers: {"Content-Type":"text/xml"},
				body: fileData};
				if jenkins_version >= 2.0
					options.headers["Jenkins-Crumb"]=crumbvalue
					options.auth.pass = jenkins_api
				request.post(options, (error, response, body) ->
					if response.statusCode==200
						dt="config modified successfully"
						msg.send dt
						setTimeout (->index.passData dt),1000
					else
						dt="Could not upload file: Response Status:"+response.statusCode
						msg.send dt
						setTimeout (->index.passData dt),1000)
