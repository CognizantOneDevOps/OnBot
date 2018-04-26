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

var request = require("request");
var exec = require('child_process').exec;
var fs = require("fs");
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";



var function_call = function (main_scalr_url, api_url, access_id, access_key, envid, signature1, callback_farm_list) {

var scalr_url = main_scalr_url;
var api_url = api_url;
var signature = signature1;
var final_scalr_url = scalr_url + api_url;
var method = 'GET';
var from_coffee_body = '';
var from_coffee_query = '';
var scalr_secret_key = access_key;
var time = null;
var scalr_key_id = access_id;

var send_error_coffee ='';
var jar_name= 'sample3';


var output_java = '';
var split_string = '';

	
	output_java = signature;

	split_string = output_java.split(" ");

	for(i=0;i<split_string.length;i++)
	{
		console.log(i+" "+split_string[i]);
		if(i == 0)
		{
			time = split_string[i];
			time = time.trim();
		}
		else if(i == 1)
		{
			signature = split_string[i];
			signature = signature.trim();
		}
	}
	
	signature = "V1-HMAC-SHA256 " + signature;




	var options = { method: 'GET',
	url: final_scalr_url,
	headers: 
	{ 
     'Content-Type': 'application/json',
     'x-scalr-signature': signature,
     'x-scalr-key-id': scalr_key_id,
     'x-scalr-date': time } };
	
	request(options, function (some_error, response, body) {
		

			if (some_error)
			{

				send_result_coffee = "Some error is there";
				send_error_coffee = "Some error is there";
				callback_farm_list("Some error is there","Some error is there","Some error is there");
		}		
			else{

			var my = JSON.stringify(body);
			var json_obj = JSON.parse(body);
			var length_body = json_obj.data.length;
			for(i=0;i<length_body;i++)
				{

					send_result_coffee = send_result_coffee + json_obj.data[i].id +" > "+json_obj.data[i].name + "\n";

				}
			send_error_coffee = "null";

			callback_farm_list(null,send_result_coffee,null);
			}
			
		
  

});


}






module.exports = {
 scalr_func: function_call	// MAIN FUNCTION
  
}
