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

var request=require('request');
var fs=require('fs');
var undeployment= function (url, username, password, version, deployedApplication, callback) {
	var xldeploy_url = url+"/deployit/deployment/prepare/undeploy/?version="+version+"&deployedApplication="+deployedApplication;
		var options = { 
auth: {
        'user': username,
        'pass': password
    },
method: 'get',
  url: xldeploy_url,
  };
  
  request(options, function (error, response, body) {
	
	
	console.log(body)
		
  if (error)
  {
	  callback(error,null,null);
  }
  if (response.statusCode!=200)
  {
	  console.log(body)
	  callback(null,null,body);
	  
	  
  }
  else{
	  var undeploydata=body;
	  var xldeploy_url = url+"/deployit/deployment"

var options = { 
auth: {
        'user': username,
        'pass': password
    },
method: 'post',
  url: xldeploy_url,
  headers: 
   {'Content-Type':'application/xml'},
  body:undeploydata};

request(options, function (error, response, body) {
	
	
	console.log(body)
	var taskid=body	
  if (error)
  {
	  callback(error,null,null);
  }
  if (response.statusCode!=200)
  {
	  console.log(body)
	  callback(null,null,body);
	  
	  
  }
  else{
	  
	  
	  var xldeploy_url = url+"/deployit/task/"+body+"/start"

var options = { 
auth: {
        'user': username,
        'pass': password
    },
method: 'post',
  url: xldeploy_url};

request(options, function (error, response, body) {
	
	if (error)
  {
	  callback(error,null,null);
  }
  if (response.statusCode!=204)
  {
	  console.log(body)
	  callback(null,null,body);
	  
	  
  }
  else{
	  console.log("undeployed");
	 callback(null,"undeployed artifact",null); 
  }
	  
});
  }
});


}
  });
}

module.exports = {
  undeployment: undeployment	// MAIN FUNCTION
  
}

