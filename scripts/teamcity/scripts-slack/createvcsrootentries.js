/*Description:
Create a VCS Root entries in build configuration.

Dependencies:
 "request"
 "fs"
*/ 
var request = require('request');
var fs = require('fs');

var vcsentry_crte = function(url,username,pwd,projectid,buildtypeid,callback){

var result="";

var headers = {
    'Content-Type':'application/xml'
};

var options = { method: 'POST',
  url: url+"/app/rest/buildTypes/"+buildtypeid+"/vcs-root-entries",
  headers: headers,
  auth: {user:username,pass:pwd},
  body: fs.createReadStream("./scripts/create_VCS_Root_Entry.xml")
  };

request(options, function (error, response, body) {
	if(error){
		result = error;
		console.log(error);
	}
  if(response.statusCode == 200){
	  result = "VCS Root entry created Successfully";
  }else{
	  result = body;
  }
    
callback([response.statusCode,result])
})
}

module.exports = {
vcsentry_crte:vcsentry_crte
}