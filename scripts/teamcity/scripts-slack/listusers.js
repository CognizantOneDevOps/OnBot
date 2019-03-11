/*Description:
List Teamcity Projects.

Dependencies:
 "request"
 "xml2js"
*/
var request = require('request');
var parseString = require('xml2js').parseString;

var usr_lst = function (url, username, pwd, callback) {

  var result = "";

  var options = {
    method: 'GET',
    url: url + "/app/rest/users",
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
          var usr_count = json.users.$.count;

          result += "\n*******************************************************************************************************************************";
          result += "\nid" + "\tusername" + "\tname";
          result += "\n*******************************************************************************************************************************";
          if (usr_count == 1) {
			  let i=0;
              result += "\n" + json.users.user[i].$.id + "\t" + json.users.user[i].$.username + "\t\t" + json.users.user[i].$.name;
          } else {
            for (var i = 0; i < usr_count; i++) {
              result += "\n" + json.users.user[i].$.id + "\t" + json.users.user[i].$.username + "\t\t" + json.users.user[i].$.name;
            }
          }
          result += "\n*******************************************************************************************************************************";

          callback(result)
        } else {
          console.log(err);
        }
      });
    }
  })
}

module.exports = {
  usr_lst: usr_lst
}