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

const elasticsearch = require('elasticsearch');
const getIndex = require('./getIndex');

const host = process.env.ELASTIC_SEARCH_IP;
const port = process.env.ELASTIC_SEARCH_PORT;
const rawIndex = 'hubot-today';

const index = getIndex(rawIndex);
const type = 'message';
const id = process.env.HUBOT_NAME + '_log';

const client = new elasticsearch.Client({
  host: `${host}:${port}`
});

module.exports.logs = (data, cb) => {
  client.index({
    index,
    type,
    body: data
  },cb);
};

module.exports.log = (data, cb) => {
  client.index({
    index,
    type,
    id,
    body: data
  },cb);
};
