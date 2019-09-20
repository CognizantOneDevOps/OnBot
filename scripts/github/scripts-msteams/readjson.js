/*Description:
 reads workflow.json to get approver id, approver name and approval flow flag

Configuration:
 None

COMMANDS:
 None

Dependencies:
 "fs": "0.0.1-security"
*/

var fs = require('fs')
var obj = '';
function readworkflow(callback) {

 if(!obj){
 obj = JSON.parse(fs.readFileSync('./workflow.json', 'utf8'));}

callback(null, obj,null);
}
module.exports = {
  readworkflow_coffee: readworkflow	// MAIN FUNCTION
  
}