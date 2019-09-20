var request=require('request'); // Requiring npm request package
var fs=require('fs'); // Requiring npm file-system package
var stopbot= function (botname,callback) {


console.log(botname)
var onbot_url = process.env.ONBOTS_URL+"/stopbot"

var options = { 

method: 'post',
  url: onbot_url,
  body:{"BotName" : botname},
  json:true
   };
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
request(options, function (error, response, body) {

if(body){
	

callback(null,body,null)
if(body.indexOf("Success")!=-1){
	var getoptions = { 

	method: 'get',
	url: process.env.ONBOTS_URL+"/newbot/"+botname,
	
	
   };
   request(getoptions, function (error, response, getbody) {
	   if(getbody){
		   getbody=JSON.parse(getbody)
		   getbody.status="off";
		   
		  var updateoptions = { 

			method: 'put',
			url: process.env.ONBOTS_URL+"/newbot/"+botname,
			body:getbody,
			json:true
	
			}; 
			request(updateoptions, function (error, response, updatebody) {
				if(updatebody){
					
				console.log(error)}
			})
	   }
	   
   })
}
}
console.log(error)
})

}

module.exports = {
  stopbot: stopbot	// MAIN FUNCTION
  
}