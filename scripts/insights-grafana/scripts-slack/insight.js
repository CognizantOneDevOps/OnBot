/*
Description:
 get dashboard list for insights-grafana bot

Configuration:
 HUBOT_GRAFANA_HOST -> Your valid Grafana host Url
 HUBOT_GRAFANA_API_KEY -> Your valid Grafana API key

Commands:

Dependencies:
 request: '*'
*/

var request = require('request');
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
var function_call = function (callback_insight) {
var headers = {
    'Authorization': 'Bearer '+process.env.HUBOT_GRAFANA_API_KEY
};

var options = {
    url: process.env.HUBOT_GRAFANA_HOST+'/api/search',
    headers: headers
};

function callback(error, response, body) {
    if (!error && response.statusCode == 200) {
		
		body = JSON.parse(body);
		
		var final_string = '*NO.* \t\t\t *ID* \t\t\t *Title* \t\t\t  \t\t\t *Name*\n';
		for(i=0;i<body.length;i++)
		{
			only_dash_name = body[i].uri.split("/")[1];
			var z = i+1;
			
			final_string = final_string + z +'\t\t\t\t'+ body[i].id +'\t\t' + body[i].title + '\t\t\t' + only_dash_name +'\n';
		}
		callback_insight(null,final_string,null);
    }
	else
	{
		callback_insight(error,"Something went wrong","Something went wrong");
	}
}

request(options, callback);
}






module.exports = {
 insight: function_call	// MAIN FUNCTION
  
}



