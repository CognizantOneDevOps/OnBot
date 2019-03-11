/*Description:
List Teamcity Projects.

Dependencies:
 "request"
 "xml2js"
*/
var request = require('request');
var parseString = require('xml2js').parseString;

var prj_lst = function (url, username, pwd, callback) {

  var result = "";

  var options = {
    method: 'GET',
    url: url + "/app/rest/projects",
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
          proj_count = json.projects.$.count;

          if (proj_count > 0) {
            result += "\n*******************************************************************************************************************************";
            result += "\nsno" + "\tproject id" + "\tproject name" + "\tproject url";
            result += "\n*******************************************************************************************************************************";
            if (proj_count == 1) {
				let i=0;
              result += "\n" + (i + 1) + "\t" + json.projects.project[i].$.id + "\t" + json.projects.project[i].$.name + "\t" + json.projects.project[i].$.webUrl;
            } else {
              for (var i = 0; i < proj_count; i++) {
                result += "\n" + (i + 1) + "\t" + json.projects.project[i].$.id + "\t" + json.projects.project[i].$.name + "\t" + json.projects.project[i].$.webUrl;
              }
            }
            result += "\n*******************************************************************************************************************************";
          } else {
            result += "\nNo projects found. Please create a new Project!";
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
  prj_lst: prj_lst
}