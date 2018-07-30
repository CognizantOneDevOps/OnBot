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

var function_call = function (nexus_repourl, username, password, repoId, reponame, callback_repo_create) {


var nexus_repourl = nexus_repourl;
var request = require("request");
var url_link = nexus_repourl+"/service/local/repositories";
var username = username;
var password = password;
var repo_primary = repoId;
var repo_name = reponame;


var options = {
	    auth: {
        'user': username,
        'pass': password
    },
	method: 'POST',
  url: url_link,
  headers: 
   { 
     
     'content-type': 'application/json'
 },
  body: 
   { data: 
      { repoType: 'proxy',
        id: repo_primary,
        name: repo_name,
        browseable: true,
        indexable: true,
        notFoundCacheTTL: 1440,
        artifactMaxAge: -1,
        metadataMaxAge: 1440,
        itemMaxAge: 1440,
        repoPolicy: 'RELEASE',
        provider: 'maven2',
        providerRole: 'org.sonatype.nexus.proxy.repository.Repository',
        downloadRemoteIndexes: true,
        autoBlockActive: true,
        fileTypeValidation: true,
        exposed: true,
        checksumPolicy: 'WARN',
        remoteStorage: 
         { remoteStorageUrl: 'http://someplace.com/repo',
           authentication: null,
           connectionSettings: null } } },
  json: true };

  
  
function callback(error, response, body) {
    if (!error) {
	
	if(JSON.stringify(response.statusCode) == '201')
	{

	callback_repo_create(null,"Created Successfully",null);
	}
	else
	{
		callback_repo_create("not200","Statuscode is not 200",null);
	}
    }
	else
	{
		callback_repo_create("ServiceDown","Status code is not 200. Service is down.",null);
	}
	
}  
  
  
request(options, callback);




}




module.exports = {
  repo_create: function_call	// MAIN FUNCTION
  
}
