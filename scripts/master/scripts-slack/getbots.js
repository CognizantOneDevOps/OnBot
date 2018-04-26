/*******************************************************************************
*Copyright 2018 Cognizant Technology Solutions
* 
* Licensed under the Apache License, Version 2.0 (the "License"); you may not
* use this file except in compliance with the License.  You may obtain a copy
* of the License at
* 
*   http://www.apache.org/licenses/LICENSE-2.0
* 
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
* WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
* License for the specific language governing permissions and limitations under
* the License.
 ******************************************************************************/

var request = require("request"); // Requiring npm request package

var function_call = function (callback_get_bots) {
	process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"; 
	var i,j;
	url = process.env.ONBOTS_URL+'/BotStore'
	var options = { method: 'GET',
		url: url
	};

	var config;
	var active_components;
	var configuration;
	request(options, function (error, response, body) {
		if(error || response.statusCode != 200)
		{
			console.log("Error in getting bots: "+error);
			callback_get_bots("Failed to fetch data. Check bot logs for error stacktrace","Error","Error");
		}
		else
		{				
			body = JSON.parse(body);
			active_components = 'BOT TEMPLATE NAME'+'		 ||		'+'BOT TYPE'+'		||		'+'DESCRIPTION'+'		||		'+'NO. OF INSTANCES'+ '		||		'+'\n'+'========================================================================================'+'\n';
			for(i in body){
				active_components += body[i].bots+'	        	||		'+body[i].BotType+'	  	||		'+body[i].Desc+'		||		'+body[i].instance +'\n'

		}
		callback_get_bots("null",active_components,"null");

		}
	});
}



module.exports = {
  get_bots : function_call	// MAIN FUNCTION
  
}
