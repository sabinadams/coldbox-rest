/**
* My RESTFul Event Handler
*/
component extends="BaseHandler" {
    property name="ordersService" inject="services.OrdersService";
    /**
    * Index
    */
	any function index( event, rc, prc ){
        var test = application.dao.read(
            sql="SELECT * FROM orders LIMIT 1",
            returnType="array"
        );
        prc.response.setData(test).setStatusCode(STATUS.ACCEPTED);
	}
    
    any function save( event, rc, prt ) {

        var body = event.getHTTPContent( json = true );

        var newID = ordersService.add(
            /**************************************************************************
             * ❌ All required fields plus whatever else gets added from the UI (TBD) *
             * ************************************************************************
             * 
             * ID = body.ID,
             * INVOICES_ID = body.INVOICES_ID, 
             * etc...
             * 
             **/
        );

        prc.response.setData({ ID: newID });
    }
}