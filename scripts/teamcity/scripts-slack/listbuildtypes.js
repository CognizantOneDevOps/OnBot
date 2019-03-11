/*Description:
List the build types.

Dependencies:
 "request"
 "xml2js"
*/
var request = require('request');
var parseString = require('xml2js').parseString;

var bld_typ_lst = function (url, username, pwd, callback) {

  var result = "";

  var options = {
    method: 'GET',
    url: url + "/app/rest/buildTypes",
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
          buildTypes_count = json.buildTypes.$.count;

          if (buildTypes_count > 0) {
            result += "\n*********************************************************************************************************************************************************************************************************************";
            result += "\nsno" + "\tbuild_type_id" + "\tbuild_type name" + "\tbuild_type_project_name" + "\tbuild_type_project_id" + "\tbuild_type_webUrl";
            result += "\n*********************************************************************************************************************************************************************************************************************";
            if (buildTypes_count == 1) {
				let i=0;
                result += "\n" + (i + 1) + "\t" + json.buildTypes.buildType[i].$.id + "\t" + json.buildTypes.buildType[i].$.name + "\t" + json.buildTypes.buildType[i].$.projectName + "\t" + json.buildTypes.buildType[i].$.projectId + "\t" + json.buildTypes.buildType[i].$.webUrl;
            } else {
              for (var i = 0; i < buildTypes_count; i++) {
                result += "\n" + (i + 1) + "\t" + json.buildTypes.buildType[i].$.id + "\t" + json.buildTypes.buildType[i].$.name + "\t" + json.buildTypes.buildType[i].$.projectName + "\t" + json.buildTypes.buildType[i].$.projectId + "\t" + json.buildTypes.buildType[i].$.webUrl;
              }
            }
            result += "\n**********************************************************************************************************************************************************************************************************************";
          } else {
            result = "NO BuildTypes found"
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
  bld_typ_lst: bld_typ_lst
}
