component singleton {
    property name="contactsService" inject="services.ContactsService";
    property name="securityService" inject="services.SecurityService";
    
    function init() { return this; }

    public struct function getBasicOrder() {
        return {test: 1, another: 2};
    }

    // Orders
    public number function addOrder( data ) {
        // Holds final data object to insert into orders table
        var order = {};
        structAppend( order, data );
        
        var company = contactsService.getCompanyByID( data.companyID );
        
        if ( 
            !( len( trim( company.account_reference ) ) ) 
            //&& application.configuration.generate_account_reference 
        ) {
            var account_reference = contactsService.generateAccountReference();
            application.dao.execute(
                sql    = "UPDATE companies SET account_reference = :accountRef WHERE ID = :companyID", 
                params = {accountRef: account_reference, companyID: data.companyID}
            );
        }
        
        var primaryContact = contactsService.getPrimaryContact( arguments.companyID );
        var addresses = application.dao.read(
            sql    = "SELECT email_address from addresses WHERE ID = :addressID",
            params = {addressID: primaryContact.addresses_ID}
        );

        order.invoice_email_address = addresses.email_address;
        order.companies_ID = data.companyID;
        order.status = 1;
        order.modified_by_users_ID = data.created_by_users_ID;
        order.modified_datetime = order.created_datetime = now();
        
        order.sales_statuses_ID = company.sales_statuses_ID;
        order.sales_status_code = contacts.getCompanySalesStatusCode( data.companyID );
        
        var newID = application.dao.insert(
            table = "orders",
            data = duplicate(order),
            insertPrimaryKeys = order.keyExists( 'ID' ),
            logEvent = securityService.logEvent,
            callbackArgs = { userID = request.userID, eventType = constants.ORDER_ADDED } // Need to make request.userID
        );

        return newID;
    }

    public void function editOrder( data ) {
        application.dao.update(
            table = "orders",
            data= duplicate(data),
            onFinish = securityService.logEvent,
            callbackArgs = { userID = request.userID, eventType = constants.ORDER_AMENDED} // Need to make request.userID
        );
    }

    public void function deleteOrder( orderID ) {
        var data = {
            ID: orderID,
            status: constants.STATUS_DELETED
        };

        application.dao.update(
            table = "orders",
            data = duplicate( data ),
            onFinish = securityService.logEvent,
            callbackArgs = {userID: request.userID, eventType = constants.ORDER_DELETED} // Need to make request.userID
        );
    }

    // Order Items
    public numeric function addOrderItem() {

    }

    public void function editOrderItem() {

    }

    public void function deleteOrderItem() {

    }

}