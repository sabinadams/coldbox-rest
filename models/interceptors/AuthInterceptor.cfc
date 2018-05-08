/**
* This interceptor secures all API requests
*/
component{
    function preProcess( event, interceptData, buffer ) {
    //         var APIUser = event.getHTTPHeader( 'APIUser', 'default' );
    // ​
    //         // Only Honest Abe can access our API
    //         if( APIUser != 'Honest Abe' ) {
    //             // Every one else will get the error response from this event
    //             event.overrideEvent('api.general.authFailed');
    //         }

            request.userID = 22222;
    }
}