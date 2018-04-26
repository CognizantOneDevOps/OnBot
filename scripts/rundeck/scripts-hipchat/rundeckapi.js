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
fs = require('fs')

function rundeck() {};
rundeck.listproj= function (url, username, password, token, callback) {
	

//api for getting list of projects
var rundeck_url = url+"/api/20/projects?format=json"

var options = { 
auth: {
        'user': username,
        'pass': password
    },
method: 'get',
  url: rundeck_url,
  headers: 
   {'X-Rundeck-Auth-Token':token  } };

request(options, function (error, response, body) {
	var res=JSON.parse(body);
	
  if (error)
  {
	  callback(error,null,null);
  }
  if (res.error)
  {
	  callback(null,null,res.message);
  }
  else{
	  var list='*NO* \t\t\t *NAME* '+"\n";
	  
	  var num;
	  
	  for(var i=0;i<res.length;i++){
		  num=i+1;
		  list+=num+'\t\t\t\t'+res[i].name+"\n";
		  
	  }
	  callback(null,list,null);
  }

  
});






}


rundeck.listjob= function (url, username, password, token, project, callback) {
	
//api for getting list of jobs for provided project

var rundeck_url = url+"/api/20/project/"+project+"/jobs?format=json"

var options = { 
auth: {
        'user': username,
        'pass': password
    },
method: 'get',
  url: rundeck_url,
  headers: 
   {'X-Rundeck-Auth-Token':token  } };

request(options, function (error, response, body) {
	var res=JSON.parse(body);
	
  if (error)
  {
	  callback(error,null,null);
  }
  if (res.error)
  {
	  callback(null,null,res.message);
  }
  else{
	  var list='\t\t\t\t *UUID* \t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t *JobName* '+"\n";
	  
        
	  
	  if(res.length==0){
		  callback(null,"no jobs yet",null);}
	  else{
		  for(var i=0;i<res.length;i++){
		    list+=res[i].id+"\t\t\t"+ res[i].name+"\n";
			
	  }
	  callback(null,list,null);
	  }
  }

  
});

}

rundeck.projconfig= function (url, username, password, token, project, callback) {
	
//api for getting configuration of provided project


var rundeck_url = url+"/api/20/project/"+project+"?format=json"

var options = { 
auth: {
        'user': username,
        'pass': password
    },
method: 'get',
  url: rundeck_url,
  headers: 
   {'X-Rundeck-Auth-Token':token  } };

request(options, function (error, response, body) {
	var res=JSON.parse(body);
	
  if (error)
  {
	  callback(error,null,null);
	  
  }
  if (res.error)
  {
	  callback(null,null,res.message);
  }
  else{
	  var list=res.config;
	  
	 callback(null,list,null);
	  
  }

  
});

}

rundeck.runjob= function (url, username, password, token, jobid, callback) {
	
//api for running job by <jobid>

var rundeck_url = url+"/api/20/job/"+jobid+"/run?format=json"


var options = { 
auth: {
        'user': username,
        'pass': password
    },
method: 'post',
  url: rundeck_url,
  headers: 
   {'X-Rundeck-Auth-Token':token  } };

request(options, function (error, response, body) {
	var res=JSON.parse(body);
	
  if (error)
  {
	  callback(error,null,null);
  }
  if (res.error)
  {
	  callback(null,null,res.message);
  }
  else{
	  var list=res.status+" "+res.id;
	  
	  
	 callback(null,list,null);
	  
  }

  
});

}


rundeck.deleteproj= function (url, username, password, token, project, callback) {

//api for deleting a project by <projectname>


var rundeck_url = url+"/api/20/project/"+project+"?format=json"

var options = { 
auth: {
        'user': username,
        'pass': password
    },
method: 'delete',
  url: rundeck_url,
  headers: 
   {'X-Rundeck-Auth-Token':token  } };

request(options, function (error, response, body) {
	if(body==""){
		callback(null,"deleted",null);
	}
	else{
	var res=JSON.parse(body);
	
  if (error)
  {
	  callback(error,null,null);
  }
  if (res.error)
  {
	  callback(null,null,res.message);
  }
  else{
	  var list=res;
	  
	  
	 callback(null,list,null);
	  
  }

  }
  
});

}


rundeck.deletejob= function (url, username, password, token, jobid, callback) {
	
//api for deleting a job by <jobid>

var rundeck_url = url+"/api/20/job/"+jobid+"?format=json"

var options = { 
auth: {
        'user': username,
        'pass': password
    },
method: 'delete',
  url: rundeck_url,
  headers: 
   {'X-Rundeck-Auth-Token':token  } };

request(options, function (error, response, body) {
	if(body==""){
		callback(null,"deleted job",null);
	}
	else{
	var res=JSON.parse(body);
	
  if (error)
  {
	  callback(error,null,null);
  }
  if (res.error)
  {
	  callback(null,null,res.message);
  }
  else{
	  var list=res;
	  
	  
	 callback(null,list,null);
	  
  }

  }
  
});

}


rundeck.exechistory= function (url, username, password, token, project, callback) {
	
//api for getting execution history of provided project


var rundeck_url = url+"/api/20/project/"+project+"/history?format=json"

var options = { 
auth: {
        'user': username,
        'pass': password
    },
method: 'delete',
  url: rundeck_url,
  headers: 
   {'X-Rundeck-Auth-Token':token  } };

request(options, function (error, response, body) {
	
	
	
	var res=JSON.parse(body);
	
  if (error)
  {
	  callback(error,null,null);
  }
  if (res.error)
  {
	  callback(null,null,res.message);
  }
  else{
	  var list="";
	  for(var i=0;i< res.events.length;i++){
		  list+="execution id: "+res.events[i].execution.id+" "+res.events[i].status+"\n";
		  
	  }
	  
	 callback(null,list,null);
	  
  }

});

}


rundeck.createproject= function (url, username, password, token, filename, callback) {
	
//api for creating a project by <configfile>
var file='./'+filename;

fs.readFile(file, 'utf8', function (err,data) {
  if (err) {
    return console.log(err);
  }
  console.log(data);
  
  
var rundeck_url = url+"/api/20/projects?format=json"

var options = { 
auth: {
        'user': username,
        'pass': password
    },
method: 'post',
  url: rundeck_url,
  headers: 
   {'X-Rundeck-Auth-Token':token ,
	'Content-Type':'application/xml'},
  body:data};

request(options, function (error, response, body) {
	
	
	console.log(body)
	var res=JSON.parse(body);
	
  if (error)
  {
	  callback(error,null,null);
  }
  if (res.error)
  {
	  callback(null,null,res.message);
  }
  else{
	  var list=res.name+" created";
	  
	  
	 callback(null,list,null);
	  
  }

});
});

}

rundeck.checkstatus=function (url, username, password, token, execid, callback) {

//api for checking status of running job

var rundeck_url = url+"/api/20/execution/"+execid+"?format=json"


var options = { 
auth: {
        'user': username,
        'pass': password
    },
method: 'get',
  url: rundeck_url,
  headers: 
   {'X-Rundeck-Auth-Token':token  } };

request(options, function (error, response, body) {
	var res=JSON.parse(body);
	
  if (error)
  {
	  callback(error,null,null);
  }
  if (res.error)
  {
	  callback(null,null,res.message);
  }
  else{
	  var list=res.status+" "+res.id;
	  
	  
	 callback(null,list,null);
	  
  }

});

}

module.exports = rundeck
