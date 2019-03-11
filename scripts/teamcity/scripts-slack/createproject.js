/*Description:
Create a Teamcity Project.

Dependencies:
 "request"
 "xml2js"
 "fs"
*/
var request = require('request');
var parseString = require('xml2js').parseString;
var fs = require('fs');

var createbuildconfig = require('./createbuildconfig.js');
var createbuildsteps = require('./createbuildsteps.js');
var createvcsroot = require('./createvcsroot.js');
var createvcsrootentries = require('./createvcsrootentries.js');

var result = "";

var prj_crte = function (url, username, pwd, projectid, buildtypeid, callback) {

  var headers = {
    'Content-Type': 'application/xml',
  }

  var options = {
    method: 'POST',
    url: url + '/app/rest/projects',
    headers: headers,
    auth: {
      user: username,
      pass: pwd
    },
    body: fs.createReadStream("./scripts/create_project.xml")
  };

  request(options, function (error, response, body) {
    if (error) {
      result = error;
      callback(result);
    }
    if (response.statusCode == 200) {
      parseString(body, function (err, json) {
        if (!err) {
          result = "Project " + json.project.$.id + " Created successfully\n";

          createbuildconfig.bldtyp_crte(url, username, pwd, projectid, buildtypeid, function (res_status) {
            result += res_status[1] + "\n";
            if (res_status[0] != 200) {
              callback(result);
            } else {
              createbuildsteps.bldstp_crte(url, username, pwd, projectid, buildtypeid, function (res_status) {
                result += res_status[1] + "\n";
                if (res_status[0] != 200) {
                  callback(result);
                } else {
                  createvcsroot.vcsroot_crte(url, username, pwd, projectid, buildtypeid, function (res_status) {
                    result += res_status[1] + "\n";
                    if (res_status[0] != 200) {
                      callback(result);
                    } else {
                      createvcsrootentries.vcsentry_crte(url, username, pwd, projectid, buildtypeid, function (res_status) {
                        result += res_status[1] + "\n";
                        if (res_status[0] != 200) {
                          callback(result);
                        } else {
                          callback(result);
                        }
                      });
                    }

                  });
                }

              });
            }

          });
        } else {
          console.log(err)
        }
      });
    } else {
      result = "Project creation failed: " + body;
      callback(result);
    }
  })
}

module.exports = {
  prj_crte: prj_crte
}