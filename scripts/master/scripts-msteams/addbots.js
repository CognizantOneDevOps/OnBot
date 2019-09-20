var request=require('request');
var fs=require('fs');
var privateurl;
var addbots= function (filename,callback) {
var auth_token = 'token='+ process.env.AUTH_TOKEN
var onbot_url = process.env.ONBOTS_URL+"/deployBot"
var headers = {
    'Authorization': "Bearer " + process.env.AUTH_TOKEN
}
var listoptions = { 

	method: 'get',
	url: "https://slack.com/api/files.list?"+auth_token
};

process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

request(listoptions, function (error, response, listbody) {
console.log(listbody)
if(listbody){
	var listbody=JSON.parse(listbody)
	var data=listbody
	for (var i = 0 ; i < data.files.length; i++)
	{
		if(data.files.length > 0 && filename == data.files[i].name)
		{
			privateurl = data.files[i].url_private.replace(/\//g,"/");
			break;
		}	
	}
	console.log(privateurl)		
	var hitoptions = 
	{
		method: 'get',
		url: privateurl,
		headers:headers
	};
console.log(hitoptions)
request(hitoptions, function (error, response, filebody) {

if(filebody){
	console.log(filebody)
	filebody=JSON.parse(filebody)
	var data=filebody
	//add to database
	var dboptions = { 
	method: 'post',
	url: process.env.ONBOTS_URL+'/newbot',
	body: data,
	json:true
	};
	var patt = /^[a-z0-9-]*$/;
	if(patt.test(data.BotName) ){
		var validateoptions = { 

		method: 'get',
		
		url: process.env.ONBOTS_URL+'/validate/'+data.BotName
	};
	
	request(validateoptions, function (error, response, validbody) {
		console.log(validbody)
		console.log(error)
		if(validbody=="valid botname"){
	
	if(data.hasOwnProperty("BotName"))
	{
	request(dboptions, function (error, response, dbbody) {

	if(dbbody){
		console.log(dbbody)
	}
	})
	data.slack="HUBOT_SLACK_TOKEN="+data.slack
	data.vars=[]
	for(var i=0;i<filebody.configuration.length;i++){
		
		data.vars.push(filebody.configuration[i].bot_env+"="+filebody.configuration[i].value)
		
	}
	console.log(data)
	var options = { 

method: 'post',
  url: onbot_url,
  headers: {"Content-type":"application/json"},
  body: data,
  json:true
   };
console.log("************ "+onbot_url)
request(options, function (error, response, body) {

if(body){
	console.log("status update")
	console.log(body)
	if(body.indexOf("error")==-1){
	data.status="on"
	var statusoptions = { 

		method: 'put',
		url: process.env.ONBOTS_URL+'/newbot/'+data.BotName,
		headers: {"Content-type":"application/json"},
		body: data,
		json:true
	};
	
	request(statusoptions, function (error, response, body) {
		console.log("success status")
		console.log("status:::"+body)
	})
	}
	var file=['.sh','.yaml']
	for(var i=0;i<file.length;i++){
	var removeoptions = { 

	method: 'get',
	url: process.env.ONBOTS_URL+"/deletefiles/"+data.BotName+file[i],
	headers: {"Content-type":"application/json"},
	
	json:true
   };
   request(removeoptions, function (error, response, removebody) {
	   
	   if(removebody){
		   console.log(removebody)
	   }
	   
   })
   }
	callback(null,body,null)

}
console.log(error)
})
}
}
else{
	callback(null,null,"bot name already exist")
}
})
}
else{
	callback(null,null,"not valid bot name")
}
}
console.log(error)



})



}

})

}

module.exports = {
  addbots: addbots	// MAIN FUNCTION
  
}
