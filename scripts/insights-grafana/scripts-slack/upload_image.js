/*
Description:
 upload grafana panel image to Slack

Configuration:
 HUBOT_SLACK_TOKEN -> Your slack token for bot userAgent

Commands:

Dependencies:
 request: '*'
 child_process: '*'
*/

var function_call = function (dash_name, panel_id, room_id, generate_id, callback_upload_image) {

var delete_flag = false;
var request = require('request');
var fs = require('fs');
var path_to_file = './scripts/'+generate_id;

var slack_api_token = process.env.HUBOT_SLACK_TOKEN;
request.post({
    url: 'https://slack.com/api/files.upload',
    formData: {
        token: slack_api_token,
        title: "Image from "+dash_name+" panel : "+panel_id,
        filename: "image.png",
        filetype: "auto",
        channels: room_id,
        file: fs.createReadStream(path_to_file),
    },
}, function (err, response) {
	console.log(err);
	
	if(!err && response.statusCode == 200)
	{
		var body_obj = JSON.parse(response.body);
		console.log('-------------->>'+body_obj.file.id);
		callback_upload_image(null,body_obj.file.id,null);
		delete_flag = true;
		var exec = require("child_process").exec
		var command = "rm -rf "+generate_id;
		exec(command, (error, stdout, stderr) => {
		console.log('Deleted the image');
		console.log(error);
		})
	}
});

	}

module.exports = {
 upload_image: function_call	// MAIN FUNCTION
  
}