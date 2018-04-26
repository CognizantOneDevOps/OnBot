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

var headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json'
};

var username = 'admin';
var password = 'admin';
var url = 'https://10.224.86.165:8443';
var fs = require('fs')
var dataString = JSON.parse(fs.readFileSync('./scripts/create_release.json', 'utf8'));

var options = {
    url: url + '/releases/',
    method: 'POST',
    headers: headers,
    body: dataString,
    auth: {
        'user': username,
        'pass': password
    }
};

function callback(error, response, body) {
    if (!error && response.statusCode == 200) {
        console.log(body);
    }
}

request(options, callback);
