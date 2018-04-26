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

var getanalytics = function(botname,callback_master_bot_analytics) 
{
	
var master_url = process.env.ONBOTS_URL + '/analytics/' + botname;

process.env.NODE_TLS_REJECT_UNAUTHORIZED="0";

var options = {
	method: 'GET',
	url: master_url,
	json:true
};

request(options, function(error, response, body)
{
	if(response.body.hits.hits.length == 0) // Check if the bot is available
	{
		callback_master_bot_analytics('Cant find the botname: '+ botname,null,null);
		
	}
	else
	{
		
		callback_master_bot_analytics(null,response.body.hits.hits[0]._source,null)
		
	}
});

}

module.exports = {
	masterbot: getanalytics	//Alias for getanalytics function
		
}

