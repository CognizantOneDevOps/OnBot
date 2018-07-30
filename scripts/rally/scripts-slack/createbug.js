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
 creates a bug in CARally

Configuration:
 None

COMMANDS:
 None

Dependencies:
 "request"
*/

var request = require("request");
var createbug = function (url, username, password, name, desc, priority, severity, state, userstoryid, callback){
var bugbody={
  "Defect": {
    "Name": name,
    "Description": desc,
    "Priority": priority,
    "Severity": severity,
    "State": state,
    "Requirement":userstoryid
  }
}
var options = { 
  url: url+"defect/create",
  headers: {"Authorization":"Bearer "+process.env.API_TOKEN},
  method:"POST",
  body:bugbody,
  json:true
	};
request(options, function (error, response, body) {
	
			if(error){
				callback(error,null,null)
			}
			if (response.statusCode!=200){
				callback(null,null,"no epics")
			}
			if (body){
			
			console.log(body)
			var message="DefectName \t\t\t DefectRef \t\t\t DefectId \t\t\t WorkspaceName \t\t\t WorkspaceId \t\t\t\t userstory\n"
			if (response.statusCode==200)
			{
				if (body.CreateResult.Errors[0]!=undefined){
					console.log(body.CreateResult.Errors[0])
					message=body.CreateResult.Errors[0]
					callback(null,null,message)
				}
				else {
					if(body.CreateResult.Object.Requirement==null){
					message+=body.CreateResult.Object._refObjectName+"\t\t\t"+body.CreateResult.Object._ref +"\t\t\t"+body.CreateResult.Object.ObjectID +"\t\t\t"+ body.CreateResult.Object.Workspace._refObjectName +"\t\t\t"+body.CreateResult.Object.Workspace._ref.split('/')[7]
					body.CreateResult.Object.Workspace._ref.split('/')[7]+"\t\t\t"+"no user story"
					}
					else{
					message+=body.CreateResult.Object._refObjectName+"\t\t\t"+body.CreateResult.Object._ref +"\t\t\t"+body.CreateResult.Object.ObjectID +"\t\t\t"+ body.CreateResult.Object.Workspace._refObjectName +"\t\t\t"+body.CreateResult.Object.Workspace._ref.split('/')[7]
					body.CreateResult.Object.Workspace._ref.split('/')[7]+"\t\t\t"+body.CreateResult.Object.Requirement._refObjectName
					}
					callback(null,message,null)
					
				}
			}
					
			
			}
			
})
}
module.exports = {
  createbug: createbug	// MAIN FUNCTION
  
}
