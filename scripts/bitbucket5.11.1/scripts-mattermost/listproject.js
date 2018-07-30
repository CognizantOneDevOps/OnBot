/*******************************************************************************
*Copyright 2018 Cognizant Technology Solutions
*  
*  Licensed under the Apache License, Version 2.0 (the "License"); you may not
*  use this file except in compliance with the License.  You may obtain a copy
*  of the License at
*  
*    http://www.apache.org/licenses/LICENSE-2.0
*  
*  Unless required by applicable law or agreed to in writing, software
*  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
*  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
*  License for the specific language governing permissions and limitations under
*  the License.
******************************************************************************/

var request = require("request");
var listproject = function (url, username, password, callback){
var options = { method: 'GET',
  url: url+'/rest/api/1.0/projects',
  auth: {
			'user': username,
			'pass': password
		}
	};
var data;
request(options, function (error, response, body) {
  if (response.statusCode!=200){
	
	callback(null,null,body.errors[0].message)
  }
  if (response.statusCode==200){
	console.log(body);
	body=JSON.parse(body)
	data='|**key**|**id**|**name**|**link**|\n'+'|:-----------:|:-----------:|:-----------:|:------------:|\n'
	for(i=0;i<body.values.length;i++){
		data+='|'+body.values[i].key+'|'+body.values[i].id+'|'+body.values[i].name+'|'+'[go to project]('+body.values[i].links.self[0].href+')'+'|\n'
		console.log(data)
		
	}
	callback(null,data,null)
  }
  if(error){
	callback(error,null,null)
  }
});
}
module.exports = {
  listproject: listproject	// MAIN FUNCTION
  
}
