/**
* My RESTFul Event Handler
*/
component extends="BaseHandler" {
    property name="myService" inject="services.MyService";
    
    /**
    * Index
    */
	any function index( event, rc, prc ){
        prc.response.setData( "Data Endpoints" );
	}
	
	any function sample( event, rc, prt ){
        prc.response
            .setMessages([
                'Message ##1',
                'Message ##2'
            ])
            .setStatusCode(STATUS.ACCEPTED)
            .setData({
                'test1': 'test1',
                'test2': 'test2',
                'add1and2': myService.add(1,2)
            });
    }
    
    any function save( event, rc, prt ) {
        prc.response.setData({
            test: "This was a post"
        });
    }
}