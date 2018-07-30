#-------------------------------------------------------------------------------
# Copyright 2018 Cognizant Technology Solutions
#   
#   Licensed under the Apache License, Version 2.0 (the "License"); you may not
#   use this file except in compliance with the License.  You may obtain a copy
#   of the License at
#   
#     http://www.apache.org/licenses/LICENSE-2.0
#   
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
#   License for the specific language governing permissions and limitations under
#   the License.
#-------------------------------------------------------------------------------

 module.exports = (robot) ->
   fs = require 'fs'
   fs.exists './logs/1.log', (exists) ->
     if exists
       startLogging()
     else
       fs.mkdir './logs/', (error) ->
         unless error
           startLogging()
         else
           console.log "Could not create logs directory: #{error}"
   startLogging = ->
     console.log "Started saving"
     robot.respond /something (.*)$/i, (msg) ->
       msg.send msg.match[1]
       
       fs.readFile logFileName(msg), (error,data) ->
         console.log "Could not log message: #{data}"
   logFileName = (msg) ->
     safe_room_name = "#{msg.message.room}".replace /[^a-z0-9]/ig, ''
     "./logs/#{1}.log"
   formatMessage = (msg) ->
     "#{msg.message.user.name}: #{msg.message.text}\n"
