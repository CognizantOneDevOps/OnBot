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
console.log(response.body.errors);
  if (error)
  {
	  callback_jira(null,null,error);
  }
  else if(response.body.errors)
  {
	  callback_jira(JSON.stringify(response.body.errors),null,null);
  }
  else
  {
	  callback_jira(null,"Successfully Created Jira issue: *"+response.body.key+"*\n"+response.body.self+"",null);
  }
});
}
module.exports = {
  create_issue: create_call	// MAIN FUNCTION
}