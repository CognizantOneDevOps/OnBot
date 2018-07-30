/*******************************************************************************
*Copyright 2018 Cognizant Technology Solutions
*  
*  Licensed under the Apache License, Version 2.0 (the "License"); you may not
*  use this file except in compliance with the License.  You may obtain a copy
*  of the License at
*  
*    http://www.apache.org/licenses/LICENSE-2.0
*  
*  Unless required by applicable law or agreed to in writing, software
*  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
*  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
*  License for the specific language governing permissions and limitations under
*  the License.
******************************************************************************/

/* Constructing Master JSON */
var HashMap = require("hashmap");
var fileSystem=require("fs");
var pathLifeCycle = "./resources/lifecyclecmdmapping/";
var pathEvent = "./resources/eventlifecyclemapping/";
var MasterJson = /** @class */ (function () {
    function MasterJson() {
        this.masterJson = MasterJson.eventLifeCycleMapping();
    }
    MasterJson.lifeCycleCmdMapping = function () {
        var lifeCycleToToolMap = new HashMap();
        fileSystem.readdirSync(pathLifeCycle).forEach(function (file) {
            var data = JSON.parse(fileSystem.readFileSync(pathLifeCycle + file, "utf-8"));
            for (var key in data)
                if (lifeCycleToToolMap.has(key))
                    lifeCycleToToolMap.get(key).set(file.replace(".json", ""), data[key]);
                else {
                    var subdata = new HashMap();
                    subdata.set(file.replace(".json", ""), data[key]);
                    lifeCycleToToolMap.set(key, subdata);
                }
        });
        return lifeCycleToToolMap;
    };
    MasterJson.eventLifeCycleMapping = function () {
        var eventLifeCycleMap = new HashMap();
        fileSystem.readdirSync(pathEvent).forEach(function (file) {
            var lifeCycleCmd = MasterJson.lifeCycleCmdMapping();
            var data = JSON.parse(fileSystem.readFileSync(pathEvent + file, "utf-8"));
            var sub1Data = new HashMap();
            for (var key in data) {
				if(data.hasOwnProperty(key)){
                var sub2Data = new HashMap();
                for (var iter1 in data[key]) {
					if(data[key].hasOwnProperty(iter1))
                    sub2Data.set(data[key][iter1], lifeCycleCmd.get(data[key][iter1]));
                }
                sub1Data.set(key, sub2Data);
				}
            }
            eventLifeCycleMap.set(file.replace(".json", ""), sub1Data);
        });
        return eventLifeCycleMap;
    };
    return MasterJson;
}());

module.exports = new MasterJson;
