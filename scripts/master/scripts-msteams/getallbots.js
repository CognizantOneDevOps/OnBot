var request=require('request'); // Requiring npm request package

var fs=require('fs'); // Requiring npm file-system package

var getallbots= function (callback) {

var onbot_url = process.env.ONBOTS_URL+"/availablebotsformanage"

var options = {

  method: 'get',
  url: onbot_url,
};

process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

request(options, function (error, response, body) {
	
if(body){
	body=JSON.parse(body)
	var allbots="   BotName   ||          BotDesc            || ProjectName || Lob || Status \n"+"================================================================================\n";
	for(var i=0;i<body.length;i++){
		
		allbots+=i+1 +"  "+body[i].BotName+" ||        "+body[i].BotDesc+"      || "+body[i].projectname+" || "+body[i].lob+" || "+body[i].status+"\n\n"
			
		
		
	}
callback(null,allbots,null)

}
console.log(error)
})

}

module.exports = {
  getallbots: getallbots	// MAIN FUNCTION
  
}