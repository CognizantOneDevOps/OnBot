var request = require("request"); // Requiring npm request package

var function_call = function (callback_get_bots) {
	process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"; 
	var i,j;
	url = process.env.ONBOTS_URL+'/BotStore'
	var options = { method: 'GET',
		url: url
	};

	var config;
	var active_components;
	var configuration;
	request(options, function (error, response, body) {
		if(error || response.statusCode != 200)
		{
			console.log("Error in getting bots: "+error);
			callback_get_bots("Failed to fetch data. Check bot logs for error stacktrace","Error","Error");
		}
		else
		{				
			body = JSON.parse(body);
			active_components = 'BOT TEMPLATE NAME'+'		 ||		'+'BOT TYPE'+'		||		'+'DESCRIPTION'+'		||		'+'NO. OF INSTANCES'+ '		||		'+'\n'+'========================================================================================'+'\n';
			for(i in body){
				active_components += body[i].bots+'	        	||		'+body[i].BotType+'	  	||		'+body[i].Desc+'		||		'+body[i].instance +'\n'

		}
		callback_get_bots("null",active_components,"null");

		}
	});
}



module.exports = {
  get_bots : function_call	// MAIN FUNCTION
  
}