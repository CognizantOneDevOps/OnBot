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

# Help Command

module.exports = (robot) ->

   robot.respond /help/i, (msg) ->
     msg.send "You are having following commands\nDescribe Issue: <project key>-<issue ID>\nList Watcher of Issue: show watchers for <Tiket number>\nCreate Issue: create jira issue in <project> with summary <summary> description <description> and issue type <issue_type>\nAssign Issue: assign jira issue <Project_id> to <user>\nAdd Comment:add comment <comment> to jira issue <project_id>\nEdit Issue: edit jira issue <project_id> with description <desc> and comment <comment>\nUpdate Summary: update summary of issue <project_id> as <summary>\nCurrent Status of Issue: upcoming status of issue <project_id>\nChange Status: change status of issue <project_id>  to <status>\nSo, what's your command?\n Use @botname for calling from chatting groups."
