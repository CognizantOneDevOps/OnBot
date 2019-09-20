var request=require('request'); // Requiring npm request package

var fs=require('fs'); // Requiring npm file system package

var deletebot= function (botname,callback) {

console.log(botname)
var onbot_url = process.env.ONBOTS_URL+"/newbot/"+botname

var options = {

  method: 'delete',
  url: onbot_url,
};

process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

request(options, function (error, response, body) {

if(body){
	console.log(body)

callback(null,botname+" is deleted",null)

}
console.log(error)
})

}

module.exports = {
  deletebot: deletebot	// MAIN FUNCTION
  
}