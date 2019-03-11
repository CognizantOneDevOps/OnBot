/*Description:
Create a VCS Root.

Dependencies:
 "request"
 "fs"
*/ 
var request = require('request');
var fs = require('fs');

var vcsroot_crte = function(url,username,pwd,projectid,buildtypeid,callback){

var result="";

var headers = {
    'Content-Type':'application/xml'
};

var options = { method: 'POST',
  url: url+"/app/rest/vcs-roots",
  headers: headers,
  auth: {user:username,pass:pwd},
  body: fs.createReadStream("./scripts/create_VCS_Root.xml")
  };

request(options, function (error, response, body) {
	if(error){
		result = error;
		console.log(error);
	}
  if(response.statusCode == 200){
	  result = "VCS Root created Successfully";
  }else{
	  result = body;
  }
    
callback([response.statusCode,result])
})
}

module.exports = {
vcsroot_crte:vcsroot_crte
}