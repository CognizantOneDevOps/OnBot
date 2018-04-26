/*******************************************************************************
*Copyright 2018 Cognizant Technology Solutions
* 
* Licensed under the Apache License, Version 2.0 (the "License"); you may not
* use this file except in compliance with the License.  You may obtain a copy
* of the License at
* 
*   http://www.apache.org/licenses/LICENSE-2.0
* 
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
* WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
* License for the specific language governing permissions and limitations under
* the License.
 ******************************************************************************/

var express = require("express");
var bodyParser = require("body-parser");
var request = require('request')
var mongojs = require('mongojs');
//MongoDB connection
var db = mongojs(process.env.MONGO_IP+'/'+process.env.MONGO_DB,[process.env.MONGO_COLL]);
require('dotenv').config()
var app = express();
var urlencodedParser = bodyParser.urlencoded({ extended: false })
app.use(bodyParser.json());
app.post('/approval', (req, res) =>{
        console.log(req.body.context)
         db.ticketgenerator.findAndModify({query:{ticketid:req.body.context.value},
                update:{$set:{approvedby:req.body.user_id,status:req.body.context.action}},
                new:false},function(err,docs){
                        //console.log(docs);
                if(docs)        {

                var botpayload=docs.payload
                botpayload["action"]=req.body.context.action;
                botpayload["approver"]=req.body.user_id;
                console.log("inside notify post")
                console.log(botpayload);
                var options = {
        uri: 'http://'+docs.payload.podIp+':'+process.env.BOT_IP+'/'+docs.payload.callback_id+'',
        
        method: 'POST',
        headers: {
            'Content-type': 'application/json'
        },
        body:botpayload,
        json: true
                }

                request(options, (error, response, body) => {
        console.log(error);

        console.log(body);
                });
                }
                else{
                        console.log(err)
                }
                });
        var appres = {
                "update": {
                        "props": {
                        "attachments": [{
                            "text": "Request is "+req.body.context.action,
                            "fields": []
                         }]
            }
        }
    };
    res.json(appres);
});

//Slack msg will be post
function sendMessageToSlackResponseURL(responseURL, JSONmessage){
    var postOptions = {
        uri: responseURL,
        method: 'POST',
        headers: {
            'Content-type': 'application/json'
        },
        json: JSONmessage
    }
    request(postOptions, (error, response, body) => {
        if (error){
            // handle errors as you see fit
        }
    })
}


app.post('/hubot/msg-callback', urlencodedParser, (req, res) =>{

        res.status(200).end() // best practice to respond with 200 status
        if(req.body.payload){

    var actionJSONPayload = JSON.parse(req.body.payload) // parse URL-encoded payload JSON string
    //console.log(actionJSONPayload);
        var postPayload=actionJSONPayload.actions[0].value;
        var tckid=actionJSONPayload.actions[0].value;
        var reqstatus=actionJSONPayload.actions[0].name;
        var approver=actionJSONPayload.user.name;
        var podIp=actionJSONPayload.podIp
		postPayload.action =actionJSONPayload.actions[0].name;
		console.log(postPayload.action)
       var message = {
	"attachments":[{"fields":[{"title":"Request History","value":actionJSONPayload.original_message.attachments[0].text},{"title":"Action Taken","value":reqstatus,"short":"true"},{"title":reqstatus+" by","value":"@"+approver,"short":"true"}],"color":"#82E0AA"}],
	"replace_original": true
    }
        sendMessageToSlackResponseURL(actionJSONPayload.response_url, message);
        
        }

        else
        {

        var actionJSONPayload = req.body // parse URL-encoded payload JSON string
        var msg=actionJSONPayload.item.message;
    var postPayload=[];
        postPayload=msg.message.split(' ');
var tckid=parseInt(postPayload[1])
        var reqstatus='';
        var approver=msg.from.name;

        if(postPayload[0]=='/approve'){
                reqstatus='Approved';
        }
        else{
                reqstatus='Rejected';
        }
    console.log(actionJSONPayload.item.room.id);
        var hipchat_url = process.env.HIPCHAT_URL+actionJSONPayload.item.room.id+"/notification?auth_token="+process.env.HIPCHAT_AUTH_TOKEN
		
        var data={"color":"green","message":approver+" has "+reqstatus+" request "+tckid,"notify":"false","message_format":"text"};
        

        var notifyoptions = {
        method: 'post',
        url: hipchat_url,
        headers:{'Content-Type':'application/json'},
        body:JSON.stringify(data)

        };

        request(notifyoptions, function (error, response, body) {


                console.log(body)

                if (error)
                {
                console.log(error)
                }


        });
		
        }
		
		
		db.ticketgenerator.findAndModify({query:{ticketid:parseInt(tckid)},
                update:{$set:{approvedby:approver,status:reqstatus}},
                new:false},function(err,docs){
						
						console.log(docs);
						
                if(docs){
 
                var botpayload=docs.payload
                botpayload["action"]=reqstatus;
                botpayload["approver"]=approver;
                
                console.log(botpayload); 
		var options = {
			uri: 'http://'+docs.payload.podIp+':'+process.env.BOT_IP+'/'+docs.payload.callback_id+'',
			method: 'POST',
			headers: {
            'Content-type': 'application/json'
			},
			json:botpayload
        }
        request(options, (error, response, body) => {
        console.log(error);
 
        console.log(body);
                });
                }
                else{
                        console.log(err)
                }
                });

})

var server = app.listen(process.env.MIDWAREPORT, function () {
    console.log("Listening on port %s...", server.address().port);
})

