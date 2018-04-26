/*******************************************************************************
*Copyright 2018 Cognizant Technology Solutions
* 
* Licensed under the Apache License, Version 2.0 (the "License"); you may not
* use this file except in compliance with the License.  You may obtain a copy
* of the License at
* 
*   http://www.apache.org/licenses/LICENSE-2.0
* 
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
* WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
* License for the specific language governing permissions and limitations under
* the License.
 ******************************************************************************/

//Load Dependency
var request = require("request");

//Function to check the available status of issue to switchon with parameters url,username,password,issue_key
var status_call = function (jira_repourl, username, password, issue_key, callback_jira_status){
var jira_repourl = jira_repourl+"/rest/api/latest/issue/"+issue_key;
var options = { 
  auth: {
        'user': username,
        'pass': password
    },
  method: 'GET',
  url: jira_repourl,
  qs: { 'expand': 'transitions' },
  json: true 
  };

request(options, function (error, response, body) {
  if (error)
  {
	  callback_jira_status("Something went wrong","Something went wrong",null);
  }
  else if(response.body)
  {
	  if(response.body.errorMessages){
	  callback_jira_status("You might not have permission or Jira Ticket Didn't Exist.","You might not have permission or Jira Ticket Didn't Exist.",response.body.errorMessages);}
	  else
	  callback_jira_status(null,response,null);
  } 
  else
  {
	  callback_jira_status(null,response,null);
  } 
});
}
module.exports = {
  status_issue: status_call	// MAIN FUNCTION 
}
