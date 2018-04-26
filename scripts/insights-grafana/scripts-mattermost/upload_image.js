/*
Description:
 upload grafana panel image to Mattermost

Configuration:
 CHANNEL_ID -> Mattermost public channel ID
 AUTH_TOKEN -> Mattermost personal Access Token with system admin permission
 MATTERMOST_INCOME_URL -> Mattermost incoming webhook for your public channel

Commands:

Dependencies:
 request: '*'
 child_process: '*'
*/

var function_call = function (dash_name, panel_id, generate_id, callback_upload_image) {

var delete_flag = false;
var request = require('request');
var fs = require('fs');
var path_to_file = './scripts/'+generate_id

request.post({
    url: process.env.MATTERMOST_INCOME_URL.split('/hooks/')[0]+'/api/v4/files',
    headers: {"Authorization":"Bearer "+process.env.AUTH_TOKEN},
    formData: {
        channel_id: process.env.CHANNEL_ID,
		client_ids: dash_name+"-"+panel_id+".png",
        files: fs.createReadStream(path_to_file)
    },
}, function (err, response, body) {
	console.log(err);
	console.log(typeof(body));
	
	if(response.statusCode == 201 && err == null)
	{
		delete_flag = true;
		var exec = require("child_process").exec
		var command = "rm "+path_to_file;
		exec(command, (error, stdout, stderr) => {
		if(error==null){
		console.log('Deleted the image');}
		else{
		console.log(error)}
		})
		callback_upload_image(null,JSON.parse(body).file_infos[0].id,null)
	}
	else{
		callback_upload_image('error',body,null);
	}
});

}

module.exports = {
 upload_image: function_call	// MAIN FUNCTION
  
}
