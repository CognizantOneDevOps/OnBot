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
# checks the status of jenkins job which are currently being built and notifies user once
# build is finished. Job status is checked from jenkins job queue.
# Main working function:checkbuildstatus
# Arguments passed: chat application id of user
# run_queue_list -> gets the job queue of jenkins which has the status of the jobs being built
# run_job_status -> checks if build is completed. If completed then notifies user
#
#Configuration:
# HUBOT_JENKINS_URL
# HUBOT_JENKINS_USER
# HUBOT_JENKINS_PASSWORD
#
#COMMANDS:
# none
#
#Dependencies:
# "request": "2.81.0"
# "elasticSearch": "^0.9.2"
#
#Note:
# Invoked from build.coffee and buildwithparam.coffee

request = require('request')
index = require('./index')
jenkins_url=process.env.HUBOT_JENKINS_URL
module.exports = (robot) ->
	module.exports.checkbuildstatus = (recipientid,jobname) ->
		dt = ''
		run_job_status = () ->
			options = {
				url: jenkins_url+'/job/'+jobname+'/lastBuild/api/json',
				method: 'GET',
				auth:{username:process.env.HUBOT_JENKINS_USER,password:process.env.HUBOT_JENKINS_PASSWORD}};
			request.get options, (error, response, body) ->
				body = JSON.parse(body);
				if body.result != "FAILURE"
					dt = "Build finished\n"+"Job name: "+body.fullDisplayName+"\nStatus: SUCCESS\nBuild Completion Time: "+new Date(body.timestamp)
					
					robot.messageRoom recipientid,dt
					index.passData dt
					clearInterval intervalid_run_job_status
				else if body.result == "FAILURE"
					dt = "Build finished\n"+"Job name: "+body.fullDisplayName+"\nStatus: "+body.result+"\nBuild Completion Time: "+new Date(body.timestamp)
					
					robot.messageRoom recipientid,dt
					index.passData dt
					clearInterval intervalid_run_job_status
				else
					console.log error
					dt = "Couldn't fetch last build status of "+jobname
					robot.messageRoom recipientid,dt
					clearInterval intervalid_run_job_status
		intervalid_run_job_status = setInterval(run_job_status, 7000)
