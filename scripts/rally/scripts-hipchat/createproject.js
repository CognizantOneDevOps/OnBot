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
 creates a project in CARally

Configuration:
 None

COMMANDS:
 None

Dependencies:
 "request"
*/

var request = require("request");
var createproject = function(url, username, password, name, workspace, state,callback) {

	var options = {
		url : url + "subscription",
		auth : {
			'user' : username,
			'pass' : password
		}
	};
	request(
			options,
			function(error, response, body) {

				if (error) {
					callback(error, null, null)
				}
				if (response.statusCode != 200) {
					
					callback(null, null, "no userstory")
				}
				var message = "ProjectName \t\t\t ProjectId\t\t\t Workspace \t\t\t WorkspaceId\n"
				if (body) {
					body = JSON.parse(body);
					var options = {
						url : body.Subscription.Workspaces._ref,
						auth : {
							'user' : username,
							'pass' : password
						}
					};
					request(
							options,
							function(error, response, body) {
								body = JSON.parse(body)

								for (var i = 0; i < body.QueryResult.Results.length; i++) {
									if (body.QueryResult.Results[i]._refObjectName == workspace) {
										var Projectbody = {
											"Project" : {
												"Name" : name,
												"Workspace" : body.QueryResult.Results[i]._ref.split('/')[7],
												"State" : state
											}
										}

										var options = {
											url : url + "project/create",
											headers : {
												"Authorization" : "Bearer "+process.env.API_TOKEN
											},
											method : "POST",
											body : Projectbody,
											json : true
										};
										request(
												options,
												function(error, response, body) {

													if (error) {
														callback(error, null,null)
													}
													if (response.statusCode != 200) {
														
														console.log(body)
														message = body.CreateResult.Errors[0]
														console.log(message)
														callback(null,null,message)
													}
													if (body) {

														var message = "ProjectName \t\t\t ProjectId \t\t\t WorkspaceName \t\t\t WorkspaceId \n"
														if (response.statusCode == 200) {
															if (body.CreateResult.Errors[0] != undefined) {

																message = body.CreateResult.Errors[0]
																console.log(message)
																callback(null,null,message)
															} else {
																message += body.CreateResult.Object._refObjectName+ "\t\t\t"+ body.CreateResult.Object._ref.split('/')[7]+ "\t\t\t"+ body.CreateResult.Object.Workspace._refObjectName+ "\t\t\t"+ body.CreateResult.Object.Workspace._ref.split('/')[7]
																
																callback(null,message,null)
																console.log(message)
															}
														}

													}

												})
									}
									else{
										callback(null,null,"no such workspace")
									}
								}
							})

					
				}

			})
}
module.exports = {
	createproject : createproject
// MAIN FUNCTION

}


