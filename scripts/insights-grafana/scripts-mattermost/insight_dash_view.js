/*
Description:
 get given dashboard details for insights-grafana bot

Configuration:
 HUBOT_GRAFANA_HOST -> Your valid Grafana host Url
 HUBOT_GRAFANA_API_KEY -> Your valid Grafana API key

Commands:

Dependencies:
 request: '*'
*/

var request = require('request');

var function_call = function (dash_name, callback_insight_dash_view) {
var headers = {
    'Authorization': 'Bearer '+process.env.HUBOT_GRAFANA_API_KEY
};

var options = {
    url: process.env.HUBOT_GRAFANA_HOST+'/api/dashboards/db/'+dash_name,
    headers: headers
};

function callback(error, response, body) {
    if (!error && response.statusCode == 200) {
		body = JSON.parse(body);
		var final_string = '| Panel-ID | Source | Panel Name | Database Type |\n|:-------:|:-------:|:-------:|:------:|\n';
		for(i=0;i<body.dashboard.rows.length;i++)
		{
			
			for(j=0;j<body.dashboard.rows[i].panels.length;j++)
			{
				final_string = final_string + '|' + body.dashboard.rows[i].panels[j].id + '| ' + body.dashboard.rows[i].panels[j].datasource + ' | ' + body.dashboard.rows[i].panels[j].title + ' | '+ body.dashboard.rows[i].panels[j].type+'|\n';
			}
		}
		callback_insight_dash_view(null,final_string,null);
    }
	else
	{
		callback_insight_dash_view("Something went wrong",error,"Something went wrong");
	}
}

request(options, callback);
}

module.exports = {
 insight_dash_view: function_call	// MAIN FUNCTION
  
}