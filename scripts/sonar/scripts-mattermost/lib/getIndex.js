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

'use strict';

const moment = require('moment');

const pattern = /\${(.*)}/;

module.exports = function (raw) {
  const matches = raw.match(pattern);

  if (matches) {
    const formatted = moment().format(matches[1]);

    return raw.replace(pattern, formatted);
  } else {
    return raw;
  }
};
