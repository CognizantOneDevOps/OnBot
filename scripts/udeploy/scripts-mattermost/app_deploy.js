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
var function_call = function (udeploy_url, user_name, user_password, app_name, app_process, env, version, component, callback_app_deploy) {
var udeploy_url = udeploy_url;

var username = user_name;
var password = user_password;

var app_name = app_name;
var app_process = app_process;
var env = env;
var version = version;
var component = component;
var component_id = ''

var componentid_options = { method: 'GET',
	url: udeploy_url + '/cli/component/info?component=' + component,
	auth: {
	user: username,
	password: password
	},
	qs: { active: 'true' }
};

//fetching the component id for notification purpose
request(componentid_options, function (error, response, body) {
	if(error || response.statusCode != 200){
		callback_app_deploy("Error",error,body)
	}
	else{
		body = JSON.parse(body);
		component_id = body.id
		console.log(component_id)
	}
});

var dataString = '{"application":"'+app_name+'","applicationProcess":"'+app_process+'","environment":"'+env+'","versions":[{"version":"'+version+'","component":"'+component+'"}]}';

var options = {
    url: udeploy_url+'/cli/applicationProcessRequest/request',
    method: 'PUT',
    body: dataString,
    auth: {
        'user': username,
        'pass': password
    }
};

function callback(error, response, body) {
	console.log(body)
	console.log(error)
    if (!error && response.statusCode == 200) {
		body = JSON.parse(body);
		var request_id = body.requestId;
		var request1 = require('request');

		var options_1 = {
		url: udeploy_url+'/cli/applicationProcessRequest/'+request_id,
		auth: {
			'user': username,
			'pass': password
		},
		method: 'GET'
	};

function callback1(error, response, body) {
	console.log(body)
	console.log(error)
	if (!error && response.statusCode == 200) {
		body = JSON.parse(body);
		console.log(body.id)
		console.log(body.name)
		console.log(body.workflowTraceId)
		 var duration = (body.duration / 60000 ).toFixed(2) + ' minutes '
		 console.log(duration)
		 console.log(typeof(body.duration))
		 var attachment = {"attachments": [{"fallback": "Deployment of **"+app_name+"** with component **"+component+"** and process **"+app_process+"** is finished\n**(RequestId: "+request_id+")**","title": "Deployment of "+app_name+" with component "+component+" and process "+app_process+" is finished\nVersion:"+version+"\n(RequestId: "+request_id+")","fields": [{"title": "Current state","value": body.state,"short": true},{"title": "Deployment result","value": body.result,"short": true},{"title": "Deployment time","value": duration,"short": true},{"title": "Enviorenment","value": env,"short": true}],"color": "#7CD197"}]}
		if(body.result!='NONE'){
			callback_app_deploy("null",attachment,"null");
			clearInterval(apiInterval);}
		else{
			var get_req_id = {url:udeploy_url+'/rest/deploy/componentProcessRequest/table?rowsPerPage=1&pageNumber=1&orderField=calendarEntry.scheduledDate&sortType=desc&filterFields=component.id&filterValue_component.id='+component_id+'&filterType_component.id=eq&filterClass_component.id=UUID&outputType=BASIC&outputType=LINKED',auth: {'user': username,'pass': password}, method: 'GET'}
			request.get(get_req_id,function(err, res, reqbody){
			reqbody = JSON.parse(reqbody)
			console.log(reqbody[0].id)
			var get_completed_child_opt = {url: udeploy_url+'/rest/workflow/componentProcessRequest/'+reqbody[0].id,auth: {'user': username,'pass': password}, method: 'GET'}
			request.get(get_completed_child_opt, function(error, response, body){
				if(!error || response.statusCode == 200){
					console.log(body)
					body = JSON.parse(body)
					var notification = {"attachments": [{"fallback": "Update: Deployment of **"+app_name+"** with component **"+component+"** and process **"+app_process+"**\n**(RequestId: "+request_id+")**","title": "Update: Deployment of "+app_name+" with component "+component+" and process "+app_process+"\nEnvironment:"+env+"\nVersion:"+version+"\n(RequestId: "+request_id+")","fields": [{"title": "The following process(s) are completed","value": "","short": true},{"title": "Result","value": "","short": true}],"color": "#45A797"}]}
					for(var i = 0; i<body.children.length; i++){
						if(body.children[i].state == 'CLOSED'){
							notification.attachments[0].fields[0].value += body.children[i].name+"\n"
							notification.attachments[0].fields[1].value += body.children[i].result+"\n"
							//Uncomment below lines to include start time, end time and duration of finished processes in notification
							
							//notification.attachments[0].fields[2].value += body.children[i].duration+"\n"
							//notification.attachments[0].fields[2].value += new Date(body.children[i].startDate).toString().substring(0,new Date(body.children[i].startDate).toString().indexOf('GMT+0530 (India Standard Time)'))+"\n"
							//notification.attachments[0].fields[3].value += new Date(body.children[i].endDate).toString().substring(0,new Date(body.children[i].endDate).toString().indexOf('GMT+0530 (India Standard Time)'))+"\n"
						}
					}
					callback_app_deploy("null",notification,"null");
				}
			})
		})
		}
	  }
}

apiInterval = setInterval(function() {request1(options_1, callback1);},1000);



    }
        else
        {
                callback_app_deploy(body,"Error","Error");
        }

}

request(options, callback);

}

module.exports = {
  app_deploy: function_call     // MAIN FUNCTION

}
