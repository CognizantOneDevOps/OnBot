var request=require('request'); // Requiring npm request package

var fs=require('fs'); // Requiring npm file-system package

var constatus= function (botname,callback) {

console.log(botname)
var onbot_url = process.env.ONBOTS_URL+"/getpodStatus/"+botname

var options = {

  method: 'get',
  url: onbot_url,

};
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

request(options, function (error, response, body) {

if(body){
	if(body)
	console.log(body)
	body=JSON.parse(body)
	var data= ""
	// Checking if mmcallURL or the port where hubot is exposed
	if(body.mmcallURL=="NA" ||body.nodePort=="NA"){
		data+=" * HostIP: "+body.hostIP+"\n * PodIP: "+body.podIP+"\n * Status: "+body.phase+"\n * MMCallbackURL: "+"NA"
	}
	else{
	data+="\n*HostIP: "+body.hostIP+"\n * PodIP: "+body.podIP+"\n * Status: "+body.phase+"\n * MMCallbackURL: "+'http://'+body.mmcallURL+':'+body.nodePort+'/hubot/incoming'
	}

callback(null,data,null)

}

console.log(error)
})

}

module.exports = {
  constatus: constatus	// MAIN FUNCTION
  
}