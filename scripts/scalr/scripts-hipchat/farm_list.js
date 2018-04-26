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

var HashMap = require('hashmap');
var request = require("request");	
var querystring = require('querystring');
var CryptoJS = require("crypto-js");
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
var function_call = function (main_scalr_url, access_id, access_key, envid, callback_farm_list) {
var path = '/api/v1beta0/user/' + envid + '/farms/';
var access_id = access_id;
var access_key = access_key;
var params = '';
var queryString, headers;
var timestamp = new Date().toISOString();
var date = timestamp;
var scalrAddress = main_scalr_url;
makeQueryString = function(params) {
    if (params.length == 0) {
      return '';
    }
    if (JSON.stringify(params) === '{}') {
      return '';
    }
    var sorted = [];
    for(var key in params) {
      sorted[sorted.length] = key;
    }
    sorted.sort();
    var result = encodeURIComponent(sorted[0]) + '=' + encodeURIComponent(params[sorted[0]]);
    for (var i = 1; i < sorted.length; i ++) {
      result += '&' + encodeURIComponent(sorted[i]) + '=' + encodeURIComponent(params[sorted[1]]);
    }
    return result;
}
    if (!params) {
      queryString = '';
    } else if (typeof params === 'string') {
      queryString = params; 
    } else {
      queryString = this.makeQueryString(params);
    }

    if (scalrAddress.endsWith('/')) {
      scalrAddress = scalrAddress.substring(0, scalrAddress.length - 1);
    }
var toSign = 'GET' + '\n' + date + '\n' + path + '\n' + '' + '\n';
var signature = CryptoJS.enc.Base64.stringify(CryptoJS.HmacSHA256(toSign, access_key));
var sign = "V1-HMAC-SHA256 "+signature;
var headers = {'X-Scalr-Key-Id': access_id,
                   'X-Scalr-Date' : date,
                   'X-Scalr-Debug' : '1',
				   'X-Scalr-Signature' : sign
				   };
var url_final = scalrAddress + path + (queryString.length > 0 ? '?' + queryString : '');
var options = { method: 'GET',
	url: url_final,
	headers: headers
	};
	
	request(options, function (error, response, body) {
		
		body = JSON.parse(body);

		var final_str = '';
		
		for(i=0;i<body.data.length;i++)
		{
			var z = i+1;
			final_str = final_str + z + " Name: " + body.data[i].name + " ID: " +body.data[i].id+ " Status: " +body.data[i].status + "\n";
		}
		

			if (error)
			{
				callback_farm_list("Something went wrong","Something went wrong","Something went wrong");
				
		}		
			else{
				
			callback_farm_list(null,final_str,null);
			
			}

});


}






module.exports = {
 farm_list: function_call	// MAIN FUNCTION
  
}
