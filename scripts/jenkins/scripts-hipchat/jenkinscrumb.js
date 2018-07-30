/*******************************************************************************
*Copyright 2018 Cognizant Technology Solutions
*  
*  Licensed under the Apache License, Version 2.0 (the "License"); you may not
*  use this file except in compliance with the License.  You may obtain a copy
*  of the License at
*  
*    http://www.apache.org/licenses/LICENSE-2.0
*  
*  Unless required by applicable law or agreed to in writing, software
*  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
*  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
*  License for the specific language governing permissions and limitations under
*  the License.
******************************************************************************/

/*Description:
 Fetches the crumb token from jenkins (for jenkins2.x versions)

COMMANDS:
 None

Configuration:
 HUBOT_JENKINS_URL
 HUBOT_JENKINS_USER
 HUBOT_JENKINS_PASSWORD
 HUBOT_JENKINS_API_TOKEN

Dependencies:
 "fs"
 "request"
*/

var request=require('request');
var fs=require('fs');
var crumb= function (callback) {

				var jenkins_url=process.env.HUBOT_JENKINS_URL
				var jenkins_user=process.env.HUBOT_JENKINS_USER
				var jenkins_pass=process.env.HUBOT_JENKINS_PASSWORD
				var jenkins_api=process.env.HUBOT_JENKINS_API_TOKEN
				var crumbvalue=''
				var url=jenkins_url+"/crumbIssuer/api/xml";
				
				options = {
				url: url,
				auth: {
					'user': jenkins_user,
					'pass': jenkins_api
				},
				method: 'GET',
				headers: {"Content-Type":"text/xml"} };
				request.get(options, function (error, response, body){
					if(body){
					result = body.split('<crumb>')
					crumbvalue = result[1].split('</crumb>')[0];
					callback (null,crumbvalue)
					}
					else{
					callback (error,null)
					}
					})
					
					}
module.exports = {
  crumb: crumb	// MAIN FUNCTION
  
}
