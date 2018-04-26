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
var function_call = function (urelease_url, username, password, callback_list_release) {
var headers = {
    'Accept': 'application/json'
};

var username = 'admin';
var password = 'admin';
var url = 'https://10.224.86.165:8443';



var options = {
    url: urelease_url + '/releases/?json&username='+username+'&password='+password,//&name=sss
    headers: headers,
    auth: {
        'user': username,
        'pass': password
    }
};

function callback(error, response, body) {
if(!error && response.statusCode == 200){     
console.log(body);
body = JSON.parse(body);
                        var length = body.length;
                        var str = '*ID*\t\t\t*NAME*\t\t\t*description*\t\t\t*teamName*\t\t\t*dateCreated*\t\t\t*createdByUserId*\n';
                        console.log(length);
                        for(i=0;i<length;i++)
                        {
                                str = str + body[i].id+' \t\t '+body[i].name+' \t\t '+body[i].description+' \t\t '+body[i].teamName+' \t\t '+body[0].dateCreated +' \t\t '+body[0].createdByUserId + '\n';
                        }

callback_list_release("null",str,"null");

}
else
{
	callback_list_release("Error","Error","Error");
}
}

request(options, callback);



}




module.exports = {
  list_release: function_call	// MAIN FUNCTION
  
}
