/*Description:
Start a build.

Dependencies:
 "request"
 "xml2js"
*/
var request = require('request');
var parseString = require('xml2js').parseString;
var fs = require('fs');

var bld_start = function (url, username, pwd, id, callback) {

  var file = fs.createWriteStream(username + "_trigger_build.xml");
  file.write("<build><buildType id=\"" + id + "\"/>");
  file.end("</build>");

  var result = "";
  var res_buildid = ""

  var headers = {
    'Content-Type': 'application/xml'
  }

  var options = {
    method: 'POST',
    url: url + '/app/rest/buildQueue',
    headers: headers,
    auth: {
      user: username,
      pass: pwd
    },
    body: fs.createReadStream(username + "_trigger_build.xml")
  };

  request(options, function (error, response, body) {
    if (error) {
      console.log(error);
    }
    if (response.statusCode == 200) {
      parseString(body, function (err, json) {
        if (!err) {
          result = "Build started Successfully for buildTypeId " + json.build.$.buildTypeId + " with the buildid " + json.build.$.id;
          res_buildid = json.build.$.id;
          callback(result, json.build.$.id)
        } else {
          console.log(err);
        }
      });
    } else {
      result = body;
      res_buildid = "";
      callback(result, res_buildid)
    }
  })
}

module.exports = {
  bld_start: bld_start
}
