/**
* My RESTFul Event Handler
*/
component extends="BaseHandler" {
    property name="ordersService" inject="services.OrdersService";
    
    this.allowedMethods = {
        index: 'GET',
        save: 'POST'
    };

	any function index( event, rc, prc ){
        var test = application.dao.read(
            sql="SELECT * FROM orders LIMIT 1",
            returnType="array"
        );
        prc.response.setData({ID: request.userID}).setStatusCode(STATUS.ACCEPTED);
	}
    
    any function save( event, rc, prt ) {

        var body = event.getHTTPContent( json = true );

        var newID = ordersService.addOrder(
            /**************************************************************************
             * ❌ All required fields plus whatever else gets added from the UI (TBD) *
             * ************************************************************************
             * 
             * ID = body.ID,
             * INVOICES_ID = body.INVOICES_ID, 
             * etc...
             * 
             **/
            companies_ID = 41,
            USERS_ID = 2,
            EXTERNAL_DOCUMENT_NO = '3',
            AI_SERVICES_ID = 4,
            CREATED_BY_USERS_ID = 5,
            DELIVER_COMPANIES_ID = 6,
            DELIVER_COMPANY = 'test1',
            DELIVER_PRIMARY_CONTACT = 0,
            DELIVER_ADDRESS1 = 'form',
            DELIVER_ADDRESS2 = 'form',
            DELIVER_ADDRESS3 = 'form',
            DELIVER_ADDRESS4 = 'form',
            DELIVER_CITY = 'form',
            DELIVER_COUNTIES_ID = 7,
            DELIVER_MOBILE1 = 'form',
            DELIVER_PHONE1 = 'form',
            DELIVER_POSTAL_CODE = 'form',
            DELIVER_STATES_ID = 8,
            INVOICE_COMPANIES_ID = 9,
            INVOICE_COMPANY = 'form',
            INVOICE_ADDRESS1 = 'form',
            INVOICE_ADDRESS2 = 'form',
            INVOICE_ADDRESS3 = 'form',
            INVOICE_ADDRESS4 = 'form',
            INVOICE_CITY = 'form',
            INVOICE_COUNTIES_ID = 10,
            INVOICE_MOBILE1 = 'form',
            INVOICE_EMAIL_ADDRESS = 'form',
            INVOICE_PHONE1 = 'form',
            INVOICE_POSTAL_CODE = 'form',
            INVOICE_STATES_ID = 11,
            DISCOUNT = 12,
            ORDER_DATETIME = now(),
            DELIVER_DATETIME = now(),
            ORDER_STATUSES_ID = 13,
            PAYMENT_TERMS_ID = 14,
            DELIVER_NOTES = 'form',
            ORDER_NOTES = 'form',
            TAX_AUTH_CODE = 'form',
            TAX_RATE = 15,
            FREIGHT_TAXABLE = 16,
            isProvisional = false,
            reference_customer = 17,
            reference_customer_name = 'form' ,
            default_locations_ID = 18,
            purchase_order_number = 'form'	
        );

        prc.response.setData({ ID: newID });
    }
}