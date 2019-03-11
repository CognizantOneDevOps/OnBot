/*Description:
Create a Teamcity user.

Dependencies:
 "request"
*/ 
var request = require('request');

var usr_crte = function(url,username,pwd,name,usrname,passwd,callback){

var data={name:name,username:usrname,password:passwd}
var result=""
var attach={
"attachments": [
	{
		"color": "#2eb886",
		"title": "User Creation",
		"text": "",
		"fields": [
			{
				"title": "",
				"value": "",
				"short": true
			},
			{
				"title": "",
				"value": "",
				"short": true
			},
			{
				"title": "",
				"value": "",
				"short": true
			},
			{
				"title": "",
				"value": "",
				"short": true
			}
		]
	}
]
};

var headers = {
    'Content-Type':     'application/json',
}

var options = { method: 'POST',
  url: url+'/app/rest/users',
  headers: headers,
  auth: {user:username,pass:pwd},
  body: JSON.stringify(data) };

request(options, function (error, response, body) {
	if(error){
		result= error;
		console.log(error);
	}
  if(response.statusCode == 200){
	  console.log("This stat");
	var json=JSON.parse(body);
	
	attach.attachments[0].text="User created successfully.Please change your password after your first login!";
	attach.attachments[0].fields[0].title="User Id";
	attach.attachments[0].fields[0].value=json["@id"];
	attach.attachments[0].fields[1].title="Name";
	attach.attachments[0].fields[1].value=json["@name"];
	attach.attachments[0].fields[2].title="Username";
	attach.attachments[0].fields[2].value=json["@username"];
	attach.attachments[0].fields[3].title="Password";
	attach.attachments[0].fields[3].value=passwd;
	result=attach;
  }else{
	attach.attachments[0].text="User creation failed: "+body;
	result=attach;
  } 
callback(result)
})}

module.exports = {
usr_crte:usr_crte
}