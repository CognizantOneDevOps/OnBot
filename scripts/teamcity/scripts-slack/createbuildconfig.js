/*Description:
Create a build configuration.

Dependencies:
 "request"
 "fs"
*/ 
var request = require('request');
var fs = require('fs');

var bldtyp_crte = function(url,username,pwd,projectid,buildtypeid,callback){

var result="";

var resp;

var headers = {
    'Content-Type':'application/xml'
};

var options = { method: 'POST',
  url: url+'/app/rest/buildTypes',
  headers: headers,
  auth: {user:username,pass:pwd},
  body: fs.createReadStream("./scripts/create_build_config.xml")
  };

request(options, function (error, response, body) {
	if(error){
		result = error;
		console.log(error);
	}
  if(response.statusCode == 200){
	  result = "BuildType created successfully";
  }else{
	  result = body;
  }
callback([response.statusCode, result]);
})
}

module.exports = {
bldtyp_crte:bldtyp_crte
} 