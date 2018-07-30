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
 lists all the test cases from CARally

Configuration:
 None

COMMANDS:
 None

Dependencies:
 "request"
*/

var request = require("request");
var listtestcases = function (url, username, password, callback){
var options = { 
  url: url+"testcase",
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
				callback(null,null,"no testcases")
			}
			if (body){
			body = JSON.parse(body);
			var feature=body.QueryResult.Results;
			var message="Name \t\t\t ObjectID \t\t\t Userstory \t\t\t Type \t\t\t Priority\n"
			
			for (var i=0;i<feature.length;i++){
				var testcaseurl=feature[i]._ref;
				var options = {url: testcaseurl,auth: {'user': process.env.USERNAME,'pass': process.env.PASSWORD}};
				request (options, function (error, response, body) {
					body = JSON.parse(body)
					console.log(body)
					if(body.TestCase.WorkProduct==null){
					message+=body.TestCase.Name+" \t\t\t "+body.TestCase.ObjectID+" \t\t\t "+"none"+" \t\t\t "+body.TestCase.Type+" \t\t\t "+body.TestCase.Priority+"\n"
					}
					else{
					message+=body.TestCase.Name+" \t\t\t "+body.TestCase.ObjectID+" \t\t\t "+body.TestCase.WorkProduct._refObjectName+" \t\t\t "+body.TestCase.Type+" \t\t\t "+body.TestCase.Priority+"\n"
					}
					console.log(message)
				})
			}
					
			setTimeout(function(){callback(null,message,null)},2000)
			}
			
})
}
module.exports = {
  listtestcases: listtestcases	// MAIN FUNCTION
  
}
