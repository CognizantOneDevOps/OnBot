//Load Dependency
var request = require("request");

//Function to check the available status of issue to switchon with parameters url,username,password,issue_key
var issue_desc = function (jira_repourl, username, password, issue_key, callback_jira_status){
var jira_repourl_browse = jira_repourl+"/browse/"+issue_key;
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
	var err = {"attachments": [{"fallback": "Jira Issue Details","author_name":"KPN Bot Framework","title": "Error","text":"","color":"#FF0000","thumb_url": "https://www.logolynx.com/images/logolynx/59/599e3c640d1a0ac8cf3de2995551178e.png"}]}
	var assignee = ''
  if (error)
  {
	err.attachments[0].text = error
	callback_jira_status(err);
  }
  else if(response.body)
  {
	  if(response.body.errorMessages){
			err.attachments[0].text = response.body.errorMessages
			callback_jira_status(err)
		}
	  else{
		  console.log(typeof(response.body.key));
		  if(response.body.fields.assignee==null){
			  assignee="no assignee";
		  }else{
			  assignee=response.body.fields.assignee.name;
		  }
 		  var attachment = "<br>Jira Key:\t"+response.body.key+"<br>Summary:\t"+response.body.fields.summary+"<br>Assignee:\t"+assignee+"<br>URL:\t"+jira_repourl_browse;
		  callback_jira_status(attachment);
	  }
  }
  else
  {
		  if(response.body.fields.assignee==null){
			  assignee="no assignee";
		  }else{
			  assignee=response.body.fields.assignee;
		  }
 		  var attachment = "<br>Jira Key:\t"+response.body.key+"<br>Summary:\t"+response.body.fields.summary+"<br>Assignee:\t"+assignee+"<br>URL:\t"+jira_repourl_browse;
		  callback_jira_status(attachment);
  }
});
}
module.exports = {
  issue_desc: issue_desc	// MAIN FUNCTION 
}