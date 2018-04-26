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

//Function to assign issue to asignee(username) with parameters url,username,password,issue_key,asignee username
var assign_call = function (jira_repourl, username, password, jira_ticket, assignee_name, callback_jira_assign){
var jira_repourl = jira_repourl+"/rest/api/2/issue/"+jira_ticket;
var errormsg, lines;
var options = {
  auth: {
        'user': username,
        'pass': password
    },
  method: 'PUT',
  url: jira_repourl,
  headers: 
   { 
   
   },
  body: {
          fields: {
                    assignee: {
                                name: assignee_name 
                              } 
                  } 
        },
  json: true 
};

request(options, function (error, response, body) {
console.log (response);
  if (error)
  {
	  callback_jira_assign("Something Went Wrong Jira ticket cannot be assigned.","Something Went Wrong Jira ticket cannot be assigned.",null);
  }
    else if(response.body)
  {
	  if(response.body.errors){
	  callback_jira_assign("Either Assignee or Jira Ticket Didn't Exist","Either Assignee or Jira Ticket Didn't Exist",response.body.errors);
	  }
  } 
  else
  {
	 callback_jira_assign(null,"Successfully Assigned",null);
  } 
});
}
module.exports = {
  assign_issue: assign_call	// MAIN FUNCTION  
}
