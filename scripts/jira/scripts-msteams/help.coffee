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
     msg.send "You are having following commands<br>1)Describe Issue: <<*projectkey*-*issueID*>><br>2)List Watcher of Issue: show watchers for <<*Tiket number*>><br>3)Create Issue: create jira issue in <<*project*>> with summary <<*summary*>> description <<*description*>> and issue type <<*issue_type*>><br>4)Assign Issue: assign jira issue <<*Project_id*>> to <<*user*>><br>5)Add Comment:add comment <<*comment*>> to jira issue <<*project_id*>><br>6)Edit Issue: edit jira issue <<*project_id*>> with description <<*desc*>> and comment <<*comment*>><br>7)Update Summary: update summary of issue <<*project_id*>> as <<*summary*>><br>8)Current Status of Issue: upcoming status of issue <<*project_id*>><br>9)Change Status: change status of issue <<*project_id*>>  to <<*status*>><br>So, what's your command?<br> Use @botname for calling from chatting groups."
