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
 lists all the tasks from CARally

Configuration:
 None

COMMANDS:
 None

Dependencies:
 "request"
*/

var request = require("request");
var listtasks = function (url, username, password, callback){
var options = { 
  url: url+"task",
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
				//body=JSON.parse(body)
				callback(null,null,"no tasks")
			}
			if (body){
			body = JSON.parse(body);
			var feature=body.QueryResult.Results;

			var message="Name \t\t\t Description \t\t\t ObjectId \t\t\t Status \t\t\t Estimate \t\t\t Userstory \t\t\t Iteration\n"
			
			for (var i=0;i<feature.length;i++){
				//url=process.env.API+"task/"+feature[i]._ref.split('/')[7];
				var taskurl=feature[i]._ref;
				console.log(taskurl)
				var options = {url: taskurl,auth: {'user': username,'pass': password}};
				request (options, function (error, response, body) {
					body = JSON.parse(body)
					
					if (body.Task.Iteration==null){
						
						message+=body.Task.Name+" \t\t\t "+body.Task.Description+" \t\t\t "+body.Task.ObjectID+" \t\t\t "+body.Task.State+" \t\t\t "+body.Task.Estimate+" \t\t\t "+body.Task.WorkProduct._refObjectName+" \t\t\t "+"not assigned"+"\n"
						
						
					}
					else{
						
						message+=body.Task.Name+" \t\t\t "+body.Task.Description+" \t\t\t "+body.Task.ObjectID+" \t\t\t "+body.Task.State+" \t\t\t "+body.Task.Estimate+" \t\t\t "+body.Task.WorkProduct._refObjectName+" \t\t\t "+body.Task.Iteration._refObjectName+"\n"
						
					}
					
				})
			}
			setTimeout(function(){callback(null,message,null)},5000)
			setTimeout(function(){console.log(message)},5000)
			}
			
})
}
module.exports = {
  listtasks: listtasks	// MAIN FUNCTION
  
}
