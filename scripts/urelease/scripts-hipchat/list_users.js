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
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

var function_call = function (urelease_url, username, password, callback_list_users) {
var options = { method: 'GET',
  url: urelease_url + '/users/name',
  qs: { json: '', username: username, password: password },
  headers:
   {

     'content-type': 'application/json',
      } };

request(options, function (error, response, body) {
  if (error){
	callback_list_users("Error","Error","Error");
  }
  else
  {
                        body = JSON.parse(body);
                        var length = body.length;
                        var str = '*ID*\t\t\t*NAME*\t\t\t*ActualName*\t\t\t*Email*\t\t\t*DisplayName*\n';
                        console.log(length);
                        for(i=0;i<length;i++)
                        {
                                str = str + body[i].id+' \t\t '+body[i].name+' \t\t '+body[i].actualName+' \t\t '+body[i].email+' \t\t '+body[0].displayName + '\n';
                        }
						
						callback_list_users("null",str,"null");

  }
});
}




module.exports = {
  list_users: function_call	// MAIN FUNCTION
  
}
