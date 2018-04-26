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

//Load dependency
var request = require("request");

//Function to add comment to particular issue with parameters url,username,password,comment,issue_key
var edit_call = function (jira_repourl, username, password, comment_jira, issue_key, callback_jira_edit){
var jira_repourl = jira_repourl+"/rest/api/2/issue/"+issue_key+"/comment";
var options = { 
  auth: {
        'user': username,
        'pass': password
    },
  method: 'POST',
  url: jira_repourl,
  headers: 
   { 
   'Content-Type': 'application/json'
   },
  body: {
          body: comment_jira 
        },
  json: true 
  };

request(options, function (error, response, body) {
  if (error)
  {
	  callback_jira_edit("Something went wrong","Something went wrong",null);
  }
  else
  {
	  callback_jira_edit(null,"Comment Posted Successfully",null);
  } 
});
}
module.exports = {
  edit_issue: edit_call	// MAIN FUNCTION  
}
