/*******************************************************************************
*Copyright 2018 Cognizant Technology Solutions
*  
*  Licensed under the Apache License, Version 2.0 (the "License"); you may not
*  use this file except in compliance with the License.  You may obtain a copy
*  of the License at
*  
*    http://www.apache.org/licenses/LICENSE-2.0
*  
*  Unless required by applicable law or agreed to in writing, software
*  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
*  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
*  License for the specific language governing permissions and limitations under
*  the License.
******************************************************************************/

/*Description:
Create a Teamcity Project.

Dependencies:
 "request"
 "xml2json"
 "fs"
*/ 
var request = require('request');
var parser = require('xml2json');
var fs = require('fs');

var createbuildconfig = require('./createbuildconfig.js');
var createbuildsteps = require('./createbuildsteps.js');
var createvcsroot = require('./createvcsroot.js');
var createvcsrootentries = require('./createvcsrootentries.js');

var result="";

var prj_crte = function(url,username,pwd,projectid,buildtypeid,callback){

var headers = {
    'Content-Type':     'application/xml',
}

var options = { method: 'POST',
  url: url+'/app/rest/projects',
  headers: headers,
  auth: {user:username,pass:pwd},
  body: fs.createReadStream("./scripts/create_project.xml") };

request(options, function (error, response, body) {
  if(error){
	  result= error;
	  callback(result);
  }
  if(response.statusCode == 200){
	var json=JSON.parse(parser.toJson(body));
	
	result="Project "+json.project.id+" Created successfully\n";
	
	createbuildconfig.bldtyp_crte(url,username,pwd,projectid,buildtypeid,function(res_status){
		result+=res_status[1]+"\n";
		if(res_status[0]!=200){
			callback(result);
		}else{
				createbuildsteps.bldstp_crte(url,username,pwd,projectid,buildtypeid,function(res_status){
					result+=res_status[1]+"\n";
					if(res_status[0]!=200){
						callback(result);
					}
					else{
						createvcsroot.vcsroot_crte(url,username,pwd,projectid,buildtypeid,function(res_status){
							result+=res_status[1]+"\n";
							if(res_status[0]!=200){
								callback(result);
							}
							else{
								createvcsrootentries.vcsentry_crte(url,username,pwd,projectid,buildtypeid,function(res_status){
									result+=res_status[1]+"\n";
									if(res_status[0]!=200){
										callback(result);
									}
									else{
										callback(result);
									}									
								});
							}
							
						});
					}
					
				});
		}
	});	
				
  }else{
	result="Project creation failed: "+body;
	callback(result);
  } 
})
}

module.exports = {
prj_crte:prj_crte
}
