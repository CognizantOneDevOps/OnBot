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

//Function to close the issue adding proper closing comment with parameters url,username,password,issue_key
var close_call = function (jira_repourl, username, password, issue_key, callback_jira_close){
var jira_repourl = jira_repourl+"/rest/api/2/issue/"+issue_key+"/transitions";
var options = { 
  auth: {
        'user': username,
        'pass': password
    },
  method: 'POST',
  url: jira_repourl,
  qs: { expand: 'transitions.fields' },
  headers: 
   { 
   'Content-Type': 'application/json'
   },
  body: { 
            transition: {
                            id: '941' 
                        }
        },
  json: true 
  };

request(options, function (error, response, body) {
	console.log (response.body);
  if (error)
  {
	  callback_jira_close("Something not well.","Something not well",null);
  }
   else if(response.body)
  {
	  if(response.body.errorMessages){
	  callback_jira_close("You might not have permission or Jira Ticket Didn't Exist","You might not have permission or Jira Ticket Didn't Exist.",response.body.errorMessages);}
  } 
  else
  {	
	  callback_jira_close(null,"Successfully Closed",body);
  } 
});
}
module.exports = {
  close_issue: close_call	// MAIN FUNCTION  
}
