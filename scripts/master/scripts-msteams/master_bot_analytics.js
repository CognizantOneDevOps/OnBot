var request = require('request'); // Importing npm request package

var getanalytics = function(botname,callback_master_bot_analytics) 
{
	
var master_url = process.env.ONBOTS_URL + '/analytics/' + botname;

process.env.NODE_TLS_REJECT_UNAUTHORIZED="0";

var options = {
	method: 'GET',
	url: master_url,
	json:true
};

request(options, function(error, response, body)
{
	if(response.body.hits.hits.length == 0) // Check if the bot is available
	{
		callback_master_bot_analytics('Cant find the botname: '+ botname,null,null);
		
	}
	else
	{
		
		callback_master_bot_analytics(null,response.body.hits.hits[0]._source,null)
		
	}
});

}

module.exports = {
	masterbot: getanalytics	//Alias for getanalytics function
		
}

