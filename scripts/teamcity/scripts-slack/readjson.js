/*Description:
 reads workflow.json to get approver id, approver name and approval flow flag

COMMANDS:
 None

Dependencies:
 "fs"
*/
var fs = require('fs')
var obj = '';
function readworkflow(callback) {

 if(!obj){
 obj = JSON.parse(fs.readFileSync('./workflow.json', 'utf8'));}

callback(null, obj,null);}
module.exports = {
  readworkflow_coffee: readworkflow	// MAIN FUNCTION 
}