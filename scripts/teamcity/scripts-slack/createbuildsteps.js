/*Description:
Create a build steps for a build in build configuration.

Dependencies:
 "request"
 "fs"
*/ 
var request = require('request');
var fs = require('fs');

var bldstp_crte = function(url,username,pwd,projectname,buildtypeid,callback){

var result="";

var headers = {
    'Content-Type':     'application/xml',
}

var options = { method: 'POST',
  url: url+'/app/rest/buildTypes/'+buildtypeid+'/steps',
  headers: headers,
  auth: {user:username,pass:pwd},
  body: fs.createReadStream("./scripts/create_build_steps.xml")
  };
  
request(options, function (error, response, body) {
  if(error){
	  result= error;
  }
  if(response.statusCode == 200){
	  result = "Build step created successfully";
  }else{
	  result = body;
  } 
callback([response.statusCode, result])
})}

module.exports = {
bldstp_crte:bldstp_crte
}