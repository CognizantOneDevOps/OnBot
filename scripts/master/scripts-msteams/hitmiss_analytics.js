var request = require('request'); // Importing npm request package

var gethitmiss = function(botname,callback_master_bot_hitmiss)
{

var master_url = process.env.ONBOTS_URL + '/totalconv/' + botname;

process.env.NODE_TLS_REJECT_UNAUTHORIZED="0";

var options = {
	method: 'GET',
	url: master_url,
	json:true
};

request(options, function(error, response, body)
{
	console.log(response);
	if(response.body.totalconv == 0) // Check if bot is available
	{
		callback_master_bot_hitmiss('Cant get the HitMiss count for : '+ botname,null,null);
		
	}
	else
	{
		callback_master_bot_hitmiss(null,response.body,null)
		
	}
});

}

module.exports = {
	masterbot_hitmiss: gethitmiss // Alias for gethitmiss function
}