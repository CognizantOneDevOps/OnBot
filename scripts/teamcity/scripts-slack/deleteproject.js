/*Description:
Delete Teamcity project.

Dependencies:
 "request"
*/ 
var request = require('request');

var prj_del = function(url,username,pwd,projectid,callback){

var result = "";

var attach={
"attachments": [
	{
		"color": "#2eb886",
		"title": "Project Deletion",
		"text": ""
	}
]
};

var options = { method: 'DELETE',
  url: url+"/app/rest/projects/"+projectid,
  auth:{user:username,pass:pwd},
};

request(options, function (error, response, body) {
	if(error){
	result = error;
	console.log(error);
	}
  if (response.statusCode==204){
  attach.attachments[0].text="Project "+projectid+" Deleted successfully.";
  result=attach;
  } else{
	attach.attachments[0].text="Project Deletion failed: "+body;
	result=attach;
  }
  callback(result);
})

}

module.exports = {
prj_del:prj_del
}