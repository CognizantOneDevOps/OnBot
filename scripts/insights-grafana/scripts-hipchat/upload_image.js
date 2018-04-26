/*
Description:
 upload grafana panel image to hipchat

Configuration:
 CHANNEL_ID -> Hipchat room API Access ID
 AUTH_TOKEN -> Hipchat personal Access Token with send_message permission

Commands:

Dependencies:
 request: '*'
 child_process: '*'
*/

var function_call = function (dash_name, panel_id, generate_id, callback_upload_image) {

var request = require('request');
var fs = require('fs');
var path_to_file = './scripts/'+generate_id;

request.post({
   url: 'https://api.hipchat.com/v2/room/'+process.env.CHANNEL_ID+'/share/file',
    headers: {"Authorization": "Bearer "+process.env.AUTH_TOKEN},
    multipart: [{
      'Content-Type': 'image/png',
      'Content-Disposition': 'attachment; name="file"; filename="'+generate_id+'"',
      'body': fs.createReadStream(path_to_file)
    }]
}, function (err, response) {
	
	if(!err && response.statusCode == 204)
	{
		callback_upload_image(null,"success",null);
	}
	else{
		callback_upload_image(err,response.body,null);
	}
	var exec = require("child_process").exec
	var command = "rm "+path_to_file;
	exec(command, (error, stdout, stderr) => {
		console.log('Deleted the image');
		if(error){console.log(error);}
	})
});

}

module.exports = {
 upload_image: function_call	// MAIN FUNCTION
  
}