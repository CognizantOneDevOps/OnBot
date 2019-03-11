/*Description:
List the build queue.

Dependencies:
 "request"
 "xml2js"
*/
var request = require('request');
var parseString = require('xml2js').parseString;

var buildqueue_lst = function (url, username, pwd, callback) {

  var result = "";

  var buildqueue_count = 0;

  var options = {
    method: 'GET',
    url: url + "/app/rest/buildQueue",
    auth: {
      user: username,
      pass: pwd
    },
  };

  request(options, function (error, response, body) {
    if (error) {
      console.log(error)
    } else {

      parseString(body, function (err, json) {
        if (!err) {

          if (json.builds.$.count > 0) {
            buildqueue_count = json.builds.$.count;
            result += "\n*******************************************************************************************************************************";
            result += "\nsno" + "\tbuild id" + "\tbuildqueue_Type_Id" + "\tState" + "\tproject url";
            result += "\n*******************************************************************************************************************************";
			console.log(json.builds.build);
            if (buildqueue_count == 1) {
				let i=0;
                result += "\n" + (i + 1) + "\t" + json.builds.build[i].$.id + "\t" + json.builds.build[i].$.buildTypeId + "\t" + json.builds.build[i].$.state + "\t" + json.builds.build[i].$.webUrl;
            } else {
              for (var i = 0; i < buildqueue_count; i++) {
                result += "\n" + (i + 1) + "\t" + json.builds.build[i].$.id + "\t" + json.builds.build[i].$.buildTypeId + "\t" + json.builds.build[i].$.state + "\t" + json.builds.build[i].$.webUrl;
              }
            }
            result += "\n*******************************************************************************************************************************";
          } else {
            result = "NO Build Queue found"
          }

          callback(result)
        } else {
          console.log(err);
        }
      });
    }


  })
}

module.exports = {
  buildqueue_lst: buildqueue_lst
}