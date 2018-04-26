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

var function_call = function (urelease_url, username, password, func, callback_notify) {


var func = func;
console.log(func);
func = func.toLowerCase();
var second_part_url = '';

if(func == 'application')
{
	second_part_url = '/applications/?json&username='+username+'&password='+password;
}
else if(func == 'release')
{
	second_part_url = '/releases/?json&username='+username+'&password='+password;
}
else if(func == 'initiative')
{
	second_part_url = '/initiatives/?json';
}
else if(func == 'users')
{
	second_part_url = '/users/name';
}
else if(func == 'roles')
{
	second_part_url = '/roles/name';
}
else
{
	callback_notify("null","Currently this is not supported","null");
}

var options = { method: 'GET',
  url: urelease_url + second_part_url,
  qs: { json: '', username: username, password: password },
  headers:
   {

     'content-type': 'application/json',
      } };

setInterval(function(){
	//console.log('In 12sec interval loop');
request(options, function (error, response, body) {
	var second_part_url1 = second_part_url;
  if (error){
        //callback_list_users("Error","Error","Error");
  }
  else
  {
                        body = JSON.parse(body);
                        var length = body.length;
                       var str = '*ID*\t\t\t*NAME*\t\t\t*ActualName*\t\t\t*Email*\t\t\t*DisplayName*\n';
                        

  }
  
  
  
  
setTimeout(function(){ 
/*interval code*/




request(options, function (error_latest, response_latest, body_latest) {
	second_part_url1 = second_part_url;
  if (error){
        //callback_list_users("Error","Error","Error");
  }
  else
  {
                        body_latest = JSON.parse(body_latest);
                        var length = body_latest.length;
                       var str = '*ID*\t\t\t*NAME*\t\t\t*ActualName*\t\t\t*Email*\t\t\t*DisplayName*\n';
                        //console.log(length);
						
								for(i=0;i<body_latest.length;i++)
								{
									flag = 0;
									  for(j=0;j<body.length;j++)
									  {
										  if(body_latest[i].name == body[j].name)
										  {
											  
											  flag = -1;
											 
											  break;
										  }
										  else
										  {
											  
										  }
									  }
									  if(flag == -1)
									  {
										 
									  }
									  else
									  {
										  console.log('New entity is added ---------- >> '+body_latest[i].name);
										  second_part_url1 = second_part_url1.split("/");
										  console.log(second_part_url1[0]+'-------------------------------'+second_part_url1[1]);
										  var s = second_part_url1[1].substring(0, second_part_url1[1].length - 1);
										  /*--------------main callback-------------*/callback_notify("null",'Latest '+s+' added : '+body_latest[i].name,"null");
									  }
									  
								}
					

                                              
  }
  
  });
  

















 }, 5000);
});

}, 5000);





}




module.exports = {
  notify: function_call     // MAIN FUNCTION

}
