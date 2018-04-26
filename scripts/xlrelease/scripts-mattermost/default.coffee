#-------------------------------------------------------------------------------
# Copyright 2018 Cognizant Technology Solutions
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License.  You may obtain a copy
# of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.
#-------------------------------------------------------------------------------

#Description:
# ensures hubot says "Sorry, I didn't get you" if user's command is not handled by hubot
#
#Configuration:
# None
#
#COMMANDS:
# none
#
#Dependencies:
# "elasticSearch": "^0.9.2"

index = require('./index')

module.exports = (robot) ->
  robot.hear /.+/, (msg) ->
    commands = ["help","reload","help","create release","start release","comment task","assign task","complete task","start task","delete task","delete release","delete template","get by title"]
    message = msg.message
    message.text = message.text or ''
    if message.text.match RegExp '^@?' + robot.name + ' +.*$', 'i'
     len = robot.name.length
     startIndex = message.text.indexOf(robot.name)
     endIndex = startIndex + len + 1
     realmsg = message.text.substr endIndex
     flag = 0
     for i in [0...commands.length]
      if realmsg.match ///.*^#{commands[i]}.*$///i
       flag = 1
      else
       #doStuff
     if flag == 0
      msg.send "Sorry, I didn't get you"
      setTimeout ( ->index.passData "Sorry, I didn't get you"),1000
