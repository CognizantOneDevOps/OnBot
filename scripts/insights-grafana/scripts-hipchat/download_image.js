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

var function_call = function (dash_name, panel_id, generate_id, callback_download_image) {
    var exec = require('child_process').exec;
	var grafana_api_key = process.env.HUBOT_GRAFANA_API_KEY;
	var url = process.env.HUBOT_GRAFANA_HOST+'/render/dashboard-solo/db/';
    var args = "curl -k -H 'Authorization: Bearer "+grafana_api_key+"' "+url+dash_name+"?panelId="+panel_id+" > ./scripts/"+generate_id+"";

    exec(args, function (error, stdout, stderr) {
      console.log('stdout: ' + stdout);
      console.log('stderr: ' + stderr);
      if(error!=null){
	callback_download_image(error,stderr,null)
      }
      else {
        callback_download_image(null,"imagedownloaded",null);
      }
    });
	
	
}

module.exports = {
 download_image: function_call	// MAIN FUNCTION
  
}
