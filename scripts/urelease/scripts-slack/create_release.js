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

var request = require('request');
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
var function_call = function (urelease_url, username, password, callback_create_release) {
var headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json'
};

var fs = require('fs')
var dataString = fs.readFileSync('./create_release.json', 'utf8');

var options = {
    url: urelease_url + '/releases/',
    method: 'POST',
    headers: headers,
    body: dataString,
    auth: {
        'user': username,
        'pass': password
    }
};

function callback(error, response, body) {
console.log(error);

    if (!error && response.statusCode == 201) {
                console.log(body);
                var str = 'Release created with ';
                body = JSON.parse(body);
                str = str + ' ID: ' +body.id + ' version: '+body.version +' name: '+ body.name +' description: '+ body.description + ' lifecyclemodel: '+body.lifecycleModel.name + 'userID: '+body.createdByUserId;
                callback_create_release("null",str,"null");
    }
	else
	{
		callback_create_release("Error","Error","Error");
	}
}

request(options, callback);
}




module.exports = {
  create_release: function_call	// MAIN FUNCTION
  
}
