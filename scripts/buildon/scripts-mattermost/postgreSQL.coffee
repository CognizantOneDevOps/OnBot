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

#Description:
#This file checks the status of a build started by buildonbot using the commitid
#
#Configuration:
#POSTGRES_LINK = currently refers to postgres database
#
#Commands:
#checkstatus <buildon_commitid> -> check the status of the given buildon_commitid
#
postgres_url=process.env.POSTGRES_LINK
pg=require('pg')
i=0
rs = ''
rows = []
tmp=''

module.exports = (robot) ->
    cmdcheckstat = new RegExp('@' + process.env.HUBOT_NAME + ' checkstatus (.*)')
    robot.listen(
      (message) ->
        return unless message.text
        message.text.match cmdcheckstat
      (msg) ->
        msg.send "Hello! you are connected to: "+postgres_url
        
        checkstat = (userid,commitid) ->
            pgClient = new (pg.Client)(postgres_url)
            pgClient.connect()
            qu = "select status from buildon_reports rep1 where commitid='"+commitid+"' and TRIGGER_FROM='BOT' order by start_timestamp desc"
            query = pgClient.query(qu)
            query.on "end", (result) ->
                tmp=result.rows
                console.log(tmp)
                for i in [0...tmp.length]
                    rows.push(tmp[i].status)
                    if(rows[i]=='FAILURE')
                        rs = "FAILED"
                console.log(!!rows.reduce (fs, nx) -> if fs == nx then fs else NaN)
                if(!!rows.reduce (fs, nx) -> if fs == nx then fs else NaN)
                    if(rows[0]=='NOTSTARTED')
                        rs = "INITIATED"
                    else
                        rs = rows[0]
                else if(rows.indexOf('NOTSTARTED')>-1)
                    if(rs == '')
                        rs = "INPROGRESS"
                else
                    rs = rows[rows.length-1]
                #msg.send rs
                robot.messageRoom userid,rs
                rows=[]
        checkstat msg.message.room,msg.match[1]
    )
