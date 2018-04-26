#-------------------------------------------------------------------------------
# Copyright 2018 Cognizant Technology Solutions
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License.  You may obtain a copy
# of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.
#-------------------------------------------------------------------------------

#Description:
# Handle commands for insights-grafana bot
#
#Configuration:
#HUBOT_GRAFANA_HOST -> Your valid Grafana host Url
#
#Commands:
# list dashboards -> list the dashboards available in your grafana host
# get dashboard <dashboard-name> -> get details of given dashboard
# list organizations -> list Dashboards available in the grafana instance you have configured
# display <dashboard-name> upto <time-in-hours-ago ex: 5/ 6/ 4> panel <panel-id> -> view the given panel of the dashboard as an image
#
#Dependencies:
# request: '*'
# unix-time: '*'

request = require('request')
unixTime = require('unix-time');
index = require('./index.js')
insight = require('./insight.js');
insight_dash_view = require('./insight_dash_view.js');
insight_org = require('./insight_org.js');
download_image = require('./download_image.js');
upload_image = require('./upload_image.js');


uniqueId = (length=8) ->
	id = ""
	id += Math.random().toString().substr(2) while id.length < length
	id.substr 0, length

module.exports = (robot) ->
	robot.respond /list dashboards/i, (msg) ->
		insight.insight (coffee_error, coffee_stdout, coffee_stderr) ->
			if coffee_error == null
				msg.reply coffee_stdout;
				setTimeout (->index.passData coffee_stdout),1000
			else
				msg.reply coffee_error;
				setTimeout (->index.passData coffee_error),1000
	
	robot.respond /get dashboard (.*)/i, (msg) ->
		dash_name = msg.match[1];
		insight_dash_view.insight_dash_view dash_name, (coffee_error, coffee_stdout, coffee_stderr) ->
			if coffee_error == null
				msg.reply coffee_stdout;
				setTimeout (->index.passData coffee_stdout),1000
			else
				msg.reply coffee_error;
				setTimeout (->index.passData coffee_error),1000
	
	robot.respond /list organizations/i, (msg) ->
		insight_org.insight_org (coffee_error, coffee_stdout, coffee_stderr) ->
			if coffee_error == null
				msg.reply coffee_stdout;
				setTimeout (->index.passData coffee_stdout),1000
			else
				msg.reply coffee_error;
				setTimeout (->index.passData coffee_error),1000
	robot.respond /display (.+)/i, (msg) ->
		if(msg.match[1].split(' ').length==1)
			dash_name = msg.match[1];
			link_to_grafana_panel = process.env.HUBOT_GRAFANA_HOST+'/dashboard/db/'+dash_name
			dt = 'Link to dashboard : '+link_to_grafana_panel
			msg.send dt
			setTimeout (->index.passData dt),1000
		else
			dash_name = msg.match[1].split(' ')[0];
			panel_id = msg.match[1].split(' ')[1];
			link_to_grafana_panel = process.env.HUBOT_GRAFANA_HOST+'/dashboard/db/'+dash_name
			dt = 'Link to dashboard : '+link_to_grafana_panel+"\nUploading panel image to slack. It might take a few moment.."
			msg.send dt
			setTimeout (->index.passData dt),1000
			
			room_id = msg.message.user.room;
			#Image generation part
			generate_id = uniqueId(4);
			generate_id = 'image'+generate_id+'.png';
			
			download_image.download_image dash_name, panel_id, generate_id, (coffee_error, coffee_stdout, coffee_stderr) ->
				if coffee_error == null
					msg.reply '';
					run = () ->
						upload_image.upload_image dash_name, panel_id, room_id, generate_id, (upload_error, upload_stdout, upload_stderr) ->
							if upload_error == null
								msg.reply '';
								id_uploaded_image = upload_stdout;
								delete_image_from_slack = () ->
									options =
										method: 'GET'
										url: 'https://slack.com/api/files.delete'
										qs:
											token: process.env.HUBOT_SLACK_TOKEN
											file: id_uploaded_image
											pretty: '1'
									request options, (error, response, body) ->
										if error
											msg.send error
										else
											console.log('Deleted');
								setTimeout(delete_image_from_slack, 1800000);
					setTimeout(run, 5000);
				else
					msg.send "Couldn't execute your command: "+coffee_stdout
					msg.send coffee_error
					setTimeout (->index.passData dt),1000
	
	robot.respond /help/i, (msg) ->
		dt = 'list dashboards -> list Dashboards available in the grafana instance you have configured\nget dashboard <dashboard-name> -> get details of given dashboard\nlist organizations -> list Dashboards available in the grafana instance you have configured\ndisplay <dashboard-name> -> get the url link to view the given dashboard\ndisplay <dashboard_name> <panel_id> -> get the url link to view the dashboard and the image of the given panel in chat room';
		msg.send dt
		setTimeout (->index.passData dt),1000
