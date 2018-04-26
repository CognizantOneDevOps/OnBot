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

var request=require('request'); // Requiring npm request package

var fs=require('fs'); // Requiring npm file system package

var deletebot= function (botname,callback) {

console.log(botname)

var onbot_url = process.env.ONBOTS_URL+"/newbot/"+botname

var options = { 

method: 'delete',
  url: onbot_url,
   };
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

request(options, function (error, response, body) {

if(body){
	console.log(body)

callback(null,botname+" is deleted",null)

}
console.log(error)
})

}

module.exports = {
  deletebot: deletebot	// MAIN FUNCTION
  
}
