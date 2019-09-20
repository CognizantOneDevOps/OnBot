//Load Dependency
var request = require("request");

//Function to check the available status of issue to switchon with parameters url,username,password,issue_key
var show_watchers = function (jira_repourl, username, password, issue_key, callback_jira_status){
var jira_repourl_browse = jira_repourl+"/browse/"+issue_key;
var jira_repourl = jira_repourl+"/rest/api/latest/issue/"+issue_key+"/watchers";
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
	  	console.log(response.statusCode);
	var err = {"attachments": [{"fallback": "Jira Issue watchers","author_name":"KPN Bot Framework","title": "Error","text":"","color":"#FF0000","thumb_url": "https://www.logolynx.com/images/logolynx/59/599e3c640d1a0ac8cf3de2995551178e.png"}]}
  if (error)
  {
	err.attachments[0].text = error
	callback_jira_status(err)
  }
  if(response.statusCode==200){
		var attachment="";// = {"attachments": [{"fallback": "Jira Issue watchers","author_name":"KPN Bot Framework","title": "Jira Issue watchers","fields": [{"short": true,"title":"Watchers","value":""}],"color": "#67B7FE","thumb_url": "https://www.logolynx.com/images/logolynx/59/599e3c640d1a0ac8cf3de2995551178e.png"}]}
		data='Watchers ';
		for(i=0;i<response.body.watchCount;i++){
			attachment="<br>Watchers<br>"+response.body.watchers[i].displayName;
			if(data!='Watchers '){
				data+=', '+response.body.watchers[i].displayName; 
			}else{
				data+=response.body.watchers[i].displayName; 
			}
		}
		if(data=='Watchers '){
			data="<br>no watchers found<br>";
			attachment= data
		}
		callback_jira_status(attachment);
  }
  else{
	err.attachments[0].title="Jira Issue watchers";
	err.attachments[0].text = issue_key+" "+body.errorMessages[0];
	callback_jira_status(err)
  }
});
}
module.exports = {
  show_watchers: show_watchers	// MAIN FUNCTION 
}