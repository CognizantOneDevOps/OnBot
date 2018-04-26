/*
Description:
 get organization details for insights-grafana bot

Configuration:
 HUBOT_GRAFANA_HOST -> Your valid Grafana host Url
 HUBOT_GRAFANA_API_KEY -> Your valid Grafana API key

Commands:

Dependencies:
 request: '*'
*/

var request = require('request');
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
var function_call = function (callback_insight_org) {
var headers = {
    'Authorization': 'Bearer '+process.env.HUBOT_GRAFANA_API_KEY
};

var options = {
    url: process.env.HUBOT_GRAFANA_HOST+'/api/org',
    headers: headers
};

function callback(error, response, body) {
	console.log(body);
	
	
    if (!error && response.statusCode == 200) {
		body = JSON.parse(body);
		final_string = '. Name :: ' + body.name + ' -- ID :: ' + body.id +'\n';
		
		callback_insight_org(null,final_string,null);
    }
	else
	{
		callback_insight_org("Something went wrong","Something went wrong","Something went wrong");
	}
}

request(options, callback);
}






module.exports = {
 insight_org: function_call	// MAIN FUNCTION
  
}



