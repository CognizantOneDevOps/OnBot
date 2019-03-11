/*Description:
To Show builds.

Dependencies:
 "request"
 "xml2js"
*/
var request = require('request');
var parseString = require('xml2js').parseString;

var bld_shw = function (url, username, pwd, bldId, bldtypid, callback) {

  var flag = true;
  var result = "";
  var res_buildid = "";
  var buildId = bldId;

  var attach = {
    "attachments": [{
      "color": "#2eb886",
      "title": "Build Details",
      "text": "",
      "fields": [{
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
    }]
  }

  var options = {
    method: 'GET',
    url: url + "/app/rest/builds/",
    auth: {
      user: username,
      pass: pwd
    },
  };

  request(options, function (error, response, body) {
    if (error) {
      console.log(error)
    };
    if (response.statusCode = 200) {
      if (error) {
        console.log(error);
      }
      parseString(body, function (err, json) {
        if (!err) {
          builds_count = json.builds.$.count;

          for (var i = 0; i < builds_count; i++) {
            if (parseInt(json.builds.build[i].$.id) == buildId || json.builds.build[i].$.buildTypeId == bldtypid) {
              flag = false;

              attach.attachments[0].text = "Build details fetched successfully."
              attach.attachments[0].fields[0].title = "BuildId";
              attach.attachments[0].fields[0].value = json.builds.build[i].$.id;
              attach.attachments[0].fields[1].title = "BuildTypeId";
              attach.attachments[0].fields[1].value = json.builds.build[i].$.buildTypeId;
              attach.attachments[0].fields[2].title = "Build Number";
              attach.attachments[0].fields[2].value = json.builds.build[i].$.number;
              attach.attachments[0].fields[3].title = "Build Status";
              attach.attachments[0].fields[3].value = json.builds.build[i].$.status;
              attach.attachments[0].fields[4].title = "Build State";
              attach.attachments[0].fields[4].value = json.builds.build[i].$.state;
              attach.attachments[0].fields[5].title = "webUrl";
              attach.attachments[0].fields[5].value = json.builds.build[i].$.webUrl;
              result = attach;

              res_buildid = json.builds.build[i].$.id;
              break;
            }
          }

          if (flag) {
            attach.attachments[0].text = "Build id provided is not valid!/Currently in Running Status!: ";
            result = attach;
          }
        } else {
          console.log(err);
        }
      });
    } else {
      result = body;
      res_buildid = "";
    }
    callback(result, res_buildid)
  })
}

module.exports = {
  bld_shw: bld_shw
}
