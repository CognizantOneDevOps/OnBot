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

var request = require('request'); // Importing npm request package

var gethitmiss = function(botname,callback_master_bot_hitmiss)
{

var master_url = process.env.ONBOTS_URL + '/totalconv/' + botname;

process.env.NODE_TLS_REJECT_UNAUTHORIZED="0";

var options = {
	method: 'GET',
	url: master_url,
	json:true
};

request(options, function(error, response, body)
{
	console.log(response);
	if(response.body.totalconv == 0) // Check if bot is available
	{
		callback_master_bot_hitmiss('Cant get the HitMiss count for : '+ botname,null,null);
		
	}
	else
	{
		callback_master_bot_hitmiss(null,response.body,null)
		
	}
});

}

module.exports = {
	masterbot_hitmiss: gethitmiss // Alias for gethitmiss function
}
