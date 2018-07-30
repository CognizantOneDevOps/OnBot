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
 lists all the projects in CARally

Configuration:
 None

COMMANDS:
 None

Dependencies:
 "request"
*/

var request = require("request");
var listproject = function (url, username, password, workspacename, callback){
var options = { 
  url: url+"subscription",
  auth: {
			'user': username,
			'pass': password
		}
	};
request(options, function (error, response, body) {
	
			if(error){
				callback(error,null,null)
			}
			if (response.statusCode!=200){
				callback(null,null,"no userstory")
			}
			var message
			if (body){
			body = JSON.parse(body);
			var options = {url: body.Subscription.Workspaces._ref,auth: {'user': username,'pass': password}};
			request (options, function (error, response, body) {
				body=JSON.parse(body)
				
				for(var i=0;i<body.QueryResult.Results.length;i++){
					if(body.QueryResult.Results[i]._refObjectName==workspacename){
						message="ProjectName \t\t\t ProjectId\t\t\t Workspace \t\t\t WorkspaceId\n"
						var options = {url: body.QueryResult.Results[i].Projects._ref,auth: {'user': username,'pass': password}};
						request (options, function (error, response, body) {
							body=JSON.parse(body)
							
							for(var i=0;i<body.QueryResult.Results.length;i++){
								message+=body.QueryResult.Results[i]._refObjectName+"\t\t\t"+body.QueryResult.Results[i]._ref.split('/')[7]+"\t\t\t"+body.QueryResult.Results[i].Workspace._refObjectName+"\t\t\t"+body.QueryResult.Results[i].Workspace._ref.split('/')[7]+"\n"
								console.log(message)
								
							}
						})
					}
					else{
						message="no such workspace"
					}
				}
			})
			
			setTimeout(function(){callback(null,message,null)},2000)
			}
			
})
}
module.exports = {
  listproject: listproject	// MAIN FUNCTION
  
}
