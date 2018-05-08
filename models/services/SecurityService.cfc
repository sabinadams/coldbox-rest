component singleton {
    function init() { return this; }

    // Used to include ScreenID. Look at old Bullseye if you need to add back in
    public function logEvent(
        required any eventType,
        required number userID,
        string table = '',
        any ID = ''
    ) {
        try{
            
            var remoteIP = structKeyExists(GetHttpRequestData().headers, "X-Forwarded-For") ?
                Trim( ListFirst(GetHttpRequestData().headers["X-Forwarded-For"]) ) :
                cgi.REMOTE_ADDR;
            
            application.dao.execute( 
                sql = "
                    INSERT INTO events ( 
                        event_types_ID, 
                        event_datetime, 
                        users_ID, 
                        remote_IP, 
                        reference, 
                        `table`, 
                        referrer, 
                        domain
                    )
                    VALUES (
                        :eventType{type='int'},
                        #createODBCDateTime(now())#,
                        :userID{type='int'},
                        :remoteIP{type='varchar'},
                        :reference{type='varchar'},
                        :table{type='varchar'},
                        :referer{type='varchar'},
                        :serverName{type='varchar'}
                    )
                ", 
                params = {
                    eventType: eventType,
                    userID: userID,
                    remoteIP: remoteIP,
                    reference: 'Updated #arguments.ID# in #arguments.table#',
                    table: table,
                    referer: left(cgi.HTTP_REFERER, 255),
                    serverName: cgi.SERVER_NAME
                }
            );
        } catch( any e) {
            writeDump(e);abort;
        }
    }
}