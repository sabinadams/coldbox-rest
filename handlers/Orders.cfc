/**
* My RESTFul Event Handler
*/
component extends="BaseHandler" {
    property name="ordersService" inject="services.OrdersService";
    
    /**
    * Index
    */
	any function index( event, rc, prc ){
        prc.response.setData( {
            test: ordersService.getBasicOrder()
        } );
	}
	
	any function sample( event, rc, prt ){
        var test = application.dao.read(
            sql="SELECT * FROM orders LIMIT 1",
            returnType="array"
        );

        prc.response.setData(test).setStatusCode(STATUS.ACCEPTED);
    }
    
    any function save( event, rc, prt ) {
        prc.response.setData({
            test: "This was a post"
        });
    }
}