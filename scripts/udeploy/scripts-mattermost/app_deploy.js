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
var function_call = function (udeploy_url, user_name, user_password, app_name, app_process, env, version, component, callback_app_deploy) {
var udeploy_url = udeploy_url;
var username = user_name;
var password = user_password;
var app_name = app_name;
var app_process = app_process;
var env = env;
var version = version;
var component = component;

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
    if (!error && response.statusCode == 200) {

                body = JSON.parse(body);
                var request_id = body.requestId;

var request1 = require('request');

var options_1 = {
    url: udeploy_url+'/cli/applicationProcessRequest/'+request_id,
    auth: {
        'user': 'admin',
        'pass': 'admin'
    }
};
                function callback1(error, response, body) {
                                if (!error && response.statusCode == 200) {
                                                body = JSON.parse(body);
                                                var final_string = 'Deployment started with requestID :: '+request_id+'\n\n\nThe deployment status matrix is :: \n'
                                                 final_string = final_string +'Application name :: '+ app_name + '\t'+'Process associated with application :: '+app_process+'\t'+'Enviorenment :: '+env+'\t' +'Type of application :: '+body.type+ '\t' +'Current state :: '+ body.state+ '\t' +'Deployment result :: '+ body.result+ '\t' +'Paused for error :: '+ body.paused+ '\t' +'Deployment time :: '+ body.duration+ '\t' +'Depending process name :: '+ body.children[0].displayName+ '\t' +'Depending process completion time :: '+ body.children[0].duration+ '\t' +'Depending component name :: '+ body.children[0].component.name+ '\t' +'Depending component description :: '+ body.children[0].component.description+ '\t' +'Depending component type :: '+ body.children[0].component.componentType+ '\t' +'Depending user name :: '+ body.children[0].component.user;
                                                callback_app_deploy("null",final_string,"null");
                                                                                                                        }
                                                        }
setTimeout(function() {request1(options_1, callback1);
}, 5000);
    }
        else
        {
                callback_app_deploy("Error","Error","Error");
        }
}
request(options, callback);

}




module.exports = {
  app_deploy: function_call     // MAIN FUNCTION

}



