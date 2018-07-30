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
 lists all the bugs from CARally

Configuration:
 None

COMMANDS:
 None

Dependencies:
 "request"
*/

var request = require("request");
var listbugs = function (url, username, password, callback){
var options = { 
  url: url+"defect",
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
				callback(null,null,"no bugs")
			}
			if (body){
			body = JSON.parse(body);
			var feature=body.QueryResult.Results;
			var message="Name \t\t\t Description \t\t\t ObjectId \t\t\t Status \t\t\t Priority \t\t\t Severity \n"
			
			for(var i=0;i<feature.length;i++) {
				var defecturl=feature[i]._ref;
				var options = {url: defecturl,auth: {'user': username,'pass':password }};
				request (options, function (error, response, body) {
					body = JSON.parse(body)
					if (body.Defect.Iteration==null){
						message+=body.Defect.Name+"\t\t\t"+body.Defect.Description+"\t\t\t"+body.Defect.ObjectID+"\t\t\t"+body.Defect.Priority+"\t\t\t"+body.Defect.Severity+"\t\t\t"+body.Defect.FlowState._refObjectName+"\n"
						console.log(message)
					}
					else{
						message+=body.Defect.Name+"\t\t\t"+body.Defect.Description+"\t\t\t"+body.Defect.ObjectID+"\t\t\t"+body.Defect.Priority+"\t\t\t"+body.Defect.Severity+"\t\t\t"+body.Defect.FlowState._refObjectName+"\n"
						console.log(message)
					}
						
				})
			}
			setTimeout(function(){callback(null,message,null)},3000);
			}
			
})
}
module.exports = {
  listbugs: listbugs	// MAIN FUNCTION
  
}
