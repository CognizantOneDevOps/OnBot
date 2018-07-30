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

var exec = require('child_process').exec;

var request = require('../node_modules/request');

var fs = require('fs');
var name1 = '';
var repo1 ='';
var branch1 = '';
var pythonservice1 = '';
var main_python_url = '';
var folder_name_in_container1 = '';
var check = '';



var result = 'false';

var function_call = function (name, repo, branch, pythonservice, url_for_pythonservice, folder_name_in_container, callback_for_token_coffee) {

name1 = name;
repo1 = repo;
branch1 = branch;
pythonservice1 = pythonservice;
folder_name_in_container1 = folder_name_in_container;

path_sample = '/tmp/'+folder_name_in_container;
  
  function wait(ms){
   var start = new Date().getTime();
   var end = start;
   while(end < start + ms) {
     end = new Date().getTime();
  }
}
  
  

filepath = "/tmp/";
filepath = filepath.concat(folder_name_in_container1);
filepath = filepath.concat("/");
filepath = filepath.concat(repo1);
filepath = filepath.concat("/.git/config");

user_name_hold_url = '';
ref_name_hold_url = '';
entire_url_from_config = '';
check = '';
fs.readFile(filepath, function (err, data) {
   if (err){
      console.log(err.stack);
      return;
   }
   data = data.toString();
   split_data = data.split("\n");
   for(i=0;i<split_data.length;i++)
   {
		split_data_1 = split_data[i].split("=");
		if(split_data_1[0].trim() == 'url')
		{
			console.log(split_data_1[0].trim()+"------------"+split_data_1[1].trim());
			user_name_hold_url = split_data_1[1].trim();
			entire_url_from_config = user_name_hold_url;
		}
		if(split_data_1[0].trim() == 'merge')
		{
			console.log(split_data_1[0].trim()+"------------"+split_data_1[1].trim());
			ref_name_hold_url = split_data_1[1].trim();
		}
		
   }
   user_name_hold_url = user_name_hold_url.split("/");
   
   console.log("Ref : "+ref_name_hold_url);//ref
   console.log("path with namespcae : "+user_name_hold_url[3].concat("/").concat(repo1));//IT IS ORGANIZATION NAME FROM CONFIG AND REPO
   
   x=(Math.random()*1e62).toString(36);
   x = x.toLowerCase();
   console.log("Namespace :: "+name1);
   
   console.log("Email :: "+name1);// NAME COMING FROM ARGUMENTS
   console.log("commit id :: "+x);//commitid
	check = x;
   console.log("name : "+repo1);
   
   var jsonobj_new = {

            ref: "a",
            project: 
            {
                path_with_namespace: "a",
                namespace: "a",
                http_url: "a"
            },
			commits: [{
			         author:
					 {
						 email: "a"
					 },
					 id: "a"
			}],
	    repository:
	    {
		name: "a",
		git_http_url: "BOT"
	    }
};
if(process.env.HUBOT_GIT_SOFTWARE == 'GitHub')
 {url_for_pythonservice = 'http://'+entire_url_from_config.substring(entire_url_from_config.indexOf('github.com/'),entire_url_from_config.length)}
jsonobj_new.ref = ref_name_hold_url;
jsonobj_new.project.path_with_namespace = user_name_hold_url[3].concat("/").concat(repo1);
jsonobj_new.project.namespace = name1;
jsonobj_new.project.http_url = url_for_pythonservice;


for(i=0;i<1;i++){
jsonobj_new.commits[i].author.email = name1;
jsonobj_new.commits[i].id = x;
}
jsonobj_new.repository.name = repo1;
jsonobj_new.repository.git_http_url = 'BOT';

   


console.log(pythonservice1);
console.log(jsonobj_new);
   
   

var urlpython = pythonservice1+"/setup";
console.log("hit pytoh url :: "+urlpython);
main_python_url = urlpython;
var headers = {
    'Content-Type': 'application/json'
};





var dataString = JSON.stringify(jsonobj_new);

var options = {
    url: urlpython,
    method: 'POST',
    body: dataString,
	headers: headers
};

function callback(error, response, body) {
    if (!error) {
	console.log(body);
	console.log(response.statusCode);
	var responsestatuscode = JSON.stringify(response.statusCode);
	if(JSON.stringify(response.statusCode) == '200')
	{
		console.log("Checking inside 200 code");
			result = "Build Started with ID :: ";
			result = result.concat(check);
			console.log(result);
			
				cmd_to_delete_tmp = 'cd /tmp && rm -rf '+folder_name_in_container1+' && dir';
	exec(cmd_to_delete_tmp, function(error, stdout, stderr) {
  
  console.log(stdout);
});
	console.log();
	callback_for_token_coffee(null,check,null);
	}
	else
	{
		var reply_str = "Service is down. Please check. Url : ".concat(main_python_url);
		
						cmd_to_delete_tmp = 'cd /tmp && rm -rf '+folder_name_in_container1+' && dir';
	exec(cmd_to_delete_tmp, function(error, stdout, stderr) {
  
  console.log(stdout);
});
	callback_for_token_coffee("Service is down",reply_str,null);
	}
    }
	else
	{
		
		console.log(error);
		cmd_to_delete_tmp = 'cd /tmp && rm -rf '+folder_name_in_container1+' && dir';
	exec(cmd_to_delete_tmp, function(error, stdout, stderr) {
  
  console.log(stdout);
});
	callback_for_token_coffee("Status code is not 200. Service is down.","Status code is not 200. Service is down.",null);
	}
	
}

request(options, callback);
});

}

function function_check() {
	

}


module.exports = {
  callname: function_call	// MAIN FUNCTION
  
}
