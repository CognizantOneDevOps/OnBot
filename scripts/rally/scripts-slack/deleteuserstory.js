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
 deletes a user story from CARally

Configuration:
 None

COMMANDS:
 None

Dependencies:
 "request"
*/

var request = require("request");
var deleteuserstory = function (url, username, password, objectid, callback){
var options = { 
  url: url+"hierarchicalrequirement/"+objectid,
  headers: {"Authorization":"Bearer "+process.env.API_TOKEN},
  method:"DELETE"
	};
request(options, function (error, response, body) {
	
			if(error){
				callback(error,null,null)
			}
			if (response.statusCode!=200){
				callback(null,null,"deletion error")
			}
			if (body){
			body = JSON.parse(body)
			var message
			if (response.statusCode==200)
			{
				if (body.OperationResult.Errors[0]!=undefined){
					console.log(body.OperationResult.Errors[0])
					message=body.OperationResult.Errors[0]
					callback(null,null,message)
				}
				else {
					console.log("Deleted Successfully ")
					message="Deleted Successfully"+ objectid
				}
			}
					
			callback(null,message,null)
			}
			
})
}
module.exports = {
  deleteuserstory: deleteuserstory	// MAIN FUNCTION
  
}
