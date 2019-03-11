/*Description:
Cancel a build in build queue.

Dependencies:
 "request"
*/ 

var request = require('request');

var bld_cancel = function(url,username,pwd,bldq,callback){

var result="";

var attach={
"attachments": [
	{
		"color": "#2eb886",
		"title": "Build Cancellation",
		"text": ""
	}
]
}

var headers = {
    'Content-Type':     'application/xml',
};

var options = { method: 'POST',
  url: url+'/app/rest/buildQueue/'+bldq,
  headers: headers,
  auth: {user:username,pass:pwd},
  body: "<buildCancelRequest comment='' readdIntoQueue='false' />" };

request(options, function (error, response, body) {
	if(error){
		console.log(error);
	}

  if(response.statusCode == 200){
	attach.attachments[0].text="Build ("+bldq+") Cancelled successfully.";
	result=attach;
  }else{
    attach.attachments[0].text="Build "+bldq+" Cancellation failed: "+body;
	result=attach;
  } 
callback(result)
})}

module.exports = {
bld_cancel:bld_cancel
}