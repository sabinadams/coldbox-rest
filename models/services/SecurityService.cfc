component singleton {
    function init() { return this; }

    public function logEvent(
        required any eventType,
        required number userID,
        string remoteIP = '',
        string table = '',
        // string screenID = '', // Still needed??
        any ID = '',
        string reference = 'Updated #arguments.ID# in #arguments.table#'
    ) {
        // local.screenID = 0;

        remoteIP = structKeyExists(GetHttpRequestData().headers, "X-Forwarded-For") ?
            Trim( ListFirst(GetHttpRequestData().headers["X-Forwarded-For"]) ) :
            cgi.REMOTE_ADDR;

        // if ( arguments.screenID == 0 ) {
        //     var referringFilename = cgi.SCRIPT_NAME;
        //     if ( left( revers(referringFilename), 1) == '/' ) {
        //         referringFilename = referringFilename & 'index.cfm';
        //     }

        //     try {
        //         local.screenID = modules.getScreenIDByFileName(referringFilename, false);
        //     } catch( any e ) {
        //         local.screenID = 0;
        //     }
        // }

        application.dao.execute( 
            sql = "
                INSERT INTO events ( 
                    `event_types_ID`, 
                    `event_datetime`, 
                    `users_ID`, 
                    `remote_IP`, 
                    `reference`, 
                    `table`, 
                    -- `screens_ID`, 
                    `referrer`, 
                    `domain`
                )
                VALUES (
                    :eventType{type='int'},
                    #createODBCDateTime(now())#,
                    :userID{type='int'},
                    :remoteIP{type='varchar'},
                    :reference{type='varchar'},
                    :table{type='varchar'},
                    -- :screenID{type='int'},
                    :referer{type='varchar'},
                    :serverName{type='varchar'}
                )
            ", 
            params = {
                eventType: eventType,
                userID: userID,
                remoteIP: remoteIP,
                reference: reference,
                table: table,
                // screenID: screenID,
                referer: left(cgi.HTTP_REFERER, 255),
                serverName: cgi.SERVER_NAME
            }
        );
    }
}