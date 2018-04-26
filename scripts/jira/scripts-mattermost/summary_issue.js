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

//Function to update summary of issue with parameters url,username,password,issue_key,summary
var summary_call = function (jira_repourl, username, password, issue_key, issue_summary, callback_jira_summary){
var jira_repourl = jira_repourl+"/rest/api/2/issue/"+issue_key;
var options = { 
  auth: {
        'user': username,
        'pass': password
    },
  method: 'PUT',
  url: jira_repourl,
  headers: 
   { 
   'Content-Type': 'application/json'
   },
  body: {
          update: {
                    summary: [{
                                set: issue_summary
                             }]
                  }
        },
  json: true 
  };

request(options, function (error, response, body) {
  if (error)
  {
	  callback_jira_summary("Something went wrong","Something went wrong",null);
  }
  else
  {
	  callback_jira_summary(null,"Summary Updated Successfully",null);
  } 
});
}
module.exports = {
  summary_issue: summary_call	// MAIN FUNCTION  
}
