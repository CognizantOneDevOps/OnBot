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

//Function to create the jira issue with parameters url,username,password,issue_key,summary,description,type of issue
var create_call = function (jira_repourl, username, password,issue_key,issue_summary,issue_description,issue_type, callback_jira){
var jira_repourl = jira_repourl+"/rest/api/2/issue/";
var issue_type = issue_type;
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
  body: 
   { 
   fields: 
      { 
	  project: { 
	              key: issue_key
			   },
        summary: issue_summary,
        description: issue_description,
        issuetype: {
                      name: issue_type
                   } 
      } 
    },
  json: true 
  };

request(options, function (error, response, body) {
console.log (response.body.errors);
  if (error)
  {
	  callback_jira("Something went wrong",null,error);
  }
  else if(response.body.errors)
  {
	  callback_jira("Correct Issue Type Is Required",null,response.body.errors);
  }
  else
  {
	  callback_jira(null,response.body.key,null);
  }
});
}
module.exports = {
  create_issue: create_call	// MAIN FUNCTION
}
