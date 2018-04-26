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

var K8s = require('k8s');
var path = require('path');
var config = require('./config/config.json');

var kubectl= K8s.kubectl({
    endpoint:config.Kubernetes_End_Point,
    binary: 'kubectl',
	kubeconfig:'admin.conf'	
});

var kubeapi= K8s.api({
	endpoint:config.Kubernetes_End_Point,
	version: '/api/v1',
	strictSSL:false,
});

var executing=false;
function kubernetesApi() { };

//Copy and Execute Scripts
copyExecute=function(path,botname,scriptname,callback){
	var copy = kubectl.command('cp '+path+' '+botname+':'+scriptname, function(err,data){ 
	if(err==null){
	 var execute =kubectl.command('exec '+botname+' -c '+botname+' sh '+scriptname, function(err, data){
		console.log("data: "+data)
		console.log("err: "+err)
	});
	 callback(null, {message: "script executed"});
	}
	});
}
//Create Kubernetes Container
kubernetesApi.createContainer = function(botname,adapter,callback) {
    var botname = botname;
	var scriptpath='app/config/'+botname+".sh";
	var scriptname=botname+".sh";	
	var finished = false
	var yaml = 'app/config/'+botname+".yaml";
	var contCreated =kubectl.pod.create(yaml,function(err,data){
		if(err){
			console.log(err)
		}
		console.log(data);	
	});

	//Wait for container to create, Copy and Execute
	var page = "notstarted";
	var last_page = "Running";
	//Find Container is UP
	(function loop() {
    	if (page.localeCompare(last_page)!=0) {
    		getPodStat(botname,function(error,result){
				if(error){
					console.log(error)
				}
				page = result.phase;
				loop();
				
			});
    	}
    	else
    	{ 
    		//Copy files and Excute once it is UP	
    		copyExecute(scriptpath,botname,scriptname, function(error, result) {
				if(error!=null){
					callback(error,{message:"Error in Container Creation"});
				}
				if(adapter=='mattermost'){
				kubectl.command('expose pod '+botname+' --name='+botname+' --external-ip='+config.exposeIP+' --type=LoadBalancer',function(err, data){
					console.log(err)
					console.log(data)
					if(err==null){
						callback(null,{message:"Container Created"});
						
					}
				})
				}
				else{callback(null,{message:"Container Created"});}
			})
		}
	}());
}
//Execute Scripts for restart bot
kubernetesApi.restartscripts = function(botname,callback) {

	var scriptname="restart"+botname+".sh";
	var path='app/config/'+scriptname;
	copyExecute(path,botname,scriptname, function(error, result) {
			if(error!=null){
				callback(error,{message:"Error in restart Hubot"});
			}
			callback(null,{message:"Hubot Restarted"});
		})
}

//Execute Scripts for stopping bot
kubernetesApi.stopscripts = function(botname,callback) {

	var scriptname="stop"+botname+".sh";
	var path='app/config/'+scriptname;
	copyExecute(path,botname,scriptname, function(error, result) {
			if(error!=null){
				callback(error,{message:"Error in stop Hubot"});
			}
			callback(null,{message:"Hubot Stopped"});
		})
}

//Execute Scripts to delete container
kubernetesApi.deleteContainer = function(botname) {
	kubectl.service.delete(botname,function(err, data){
						
						if(data){
						
						kubeapi.delete('namespaces/default/pods/'+botname).then(function(data){	
							return "pod & service deleted";
		

						}).catch(function(err){
							return "error in delete";
						})
						}
						else{
						kubeapi.delete('namespaces/default/pods/'+botname).then(function(data){	
							return "pod deleted";
		

						}).catch(function(err){
							return "error in delete";
						})

						}
	})
	
}

//Read Log from Bots
kubernetesApi.readlog=function(botname,callback){

	 var execute =kubectl.command('exec '+botname+' -c '+botname+' cat '+"myhubot/hubot.log", function(err, data){
			if(err!=null)	{
			callback(err,"error occured while reading");
			}
			else{
			callback(null,data);
			}
				
		});
	}
	
	//Get Coffee/workflow.json Content
	kubernetesApi.coffeecontenet=function(filename,botname,callback){
		if(filename=='workflow.json'){
				var execute =kubectl.command('exec '+botname+' -c '+botname+' cat '+"myhubot/"+filename, function(err, data){
				if(err!=null)	{
				callback(err,"error occured while reading");
				}
				else{
				callback(null,data);
				}	
			});
		}
		else{
			var execute =kubectl.command('exec '+botname+' -c '+botname+' cat '+"myhubot/scripts/"+filename, function(err, data){
				if(err!=null)	{
				callback(err,"error occured while reading");
				}
				else{
				callback(null,data);
				}
					
			});
		}
	}



//Update coffee/workflow.json file inside container
kubernetesApi.editCoffee=function(botname,filename,path,callback){

	if(filename=='workflow.json'){
		var copy = kubectl.command('cp '+ path + ' ' + botname +':/home/myhubot/'+filename, function(err,data){
			if(err!=null)	{
				console.log(err)
				callback(err,"error occured while copying to container");
			}
			else{
				callback(null,botname);
			}	
		});
	}
	else{
	 var copy = kubectl.command('cp '+ path + ' ' + botname +':/home/myhubot/scripts/'+filename, function(err,data){
			if(err!=null)	{
				callback(err,"error occured while copying to container");
			}
			else{
				callback(null,botname);
			}	
		});
	}
}
//checking whether restart script is present inside container
kubernetesApi.checkRestartScript = function(botname,callback){
	var check =kubectl.command('exec '+botname+' -c '+botname+' cat restart'+botname+'.sh', function(err, data){
		if(err!=null){
			callback(err,"not found");
		}
		else{
			callback(null,"found");	
		}		
	});
}

//excute bot restart script inside container
kubernetesApi.executeRestart = function(botname,callback){
	var error;
	var st = kubectl.command('exec '+botname+' -c '+botname+' sh restart'+botname+'.sh', function(err, data){
				if(data){console.log(data);}
				else{console.log("err"+err);
				error=err;}
				
		});
		callback(error,"success");
}
//Get pod Status
kubernetesApi.getPodStatus = function(botname,callback) {
 kubectl.command('get pod '+botname+' --output=json', function(err, pod){
	if(err){
		callback(err,{hostIP:"NA",podIP:"NA",phase:"Stopped",startTime:"NA",nodePort:"NA",mmcallURL:'NA'});
	}
	else{
	kubectl.service.get(botname,function(err, data){
				if(err==null){
				var nodePort=data.spec.ports[0].nodePort;
				var mmcallURL=data.spec.externalIPs[0];
				callback(null,{hostIP:pod.status.hostIP,podIP:pod.status.podIP,phase:pod.status.phase,startTime:pod.status.startTime,nodePort:nodePort,mmcallURL:mmcallURL});
				}
				else{
				
				callback(err,{hostIP:pod.status.hostIP,podIP:pod.status.podIP,phase:pod.status.phase,startTime:pod.status.startTime,nodePort:"NA",mmcallURL:'NA'});
				}
	})
	}
});
}
//check whether container is created
getPodStat = function(botname,callback) {

 kubectl.command('get pod '+botname+' --output=json', function(err, pod){
	if(err){
		callback(err,{phase:"Stopped"});
	}
	
	callback(null,{phase:pod.status.phase});
	

});
}

module.exports = kubernetesApi;
