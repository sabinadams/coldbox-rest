component singleton {
    property name="contactsService" inject="services.ContactsService";
    property name="securityService" inject="services.SecurityService";

    function init() { return this; }
    
    // Orders
    public number function addOrder( 
        required number COMPANIES_ID,
        required number USERS_ID,
        required CREATED_BY_USERS_ID,
        required date ORDER_DATETIME,
        required date DELIVER_DATETIME,
        required number ORDER_STATUSES_ID,
        required number DELIVER_COMPANIES_ID,
        required string DELIVER_COMPANY,
        required string DELIVER_ADDRESS1,
        required string DELIVER_CITY,
        required string DELIVER_POSTAL_CODE,
        required number INVOICE_COMPANIES_ID,
        required string INVOICE_COMPANY,
        required string INVOICE_ADDRESS1,
        required string INVOICE_CITY,
        required number PAYMENT_TERMS_ID,
        required string TAX_AUTH_CODE,
        required number TAX_RATE,
        required number FREIGHT_TAXABLE,
        number ID,
        string EXTERNAL_DOCUMENT_NO,
        number AI_SERVICES_ID = 0,
        number DELIVER_PRIMARY_CONTACT = 0,
        string DELIVER_ADDRESS2 = "",
        string DELIVER_ADDRESS3 = "",
        string DELIVER_ADDRESS4 = "",
        string DELIVER_ADDRESS5 = "",
        string DELIVER_ADDRESS6 = "",
        number DELIVER_COUNTIES_ID = 0,
        string DELIVER_MOBILE1 = "",
        string DELIVER_PHONE1 = "",
        number DELIVER_STATES_ID = 0,
        string INVOICE_ADDRESS2 = "",
        string INVOICE_ADDRESS3 = "",
        string INVOICE_ADDRESS4 = "",
        string INVOICE_ADDRESS5 = "",
        string INVOICE_ADDRESS6 = "",
        number INVOICE_COUNTIES_ID = 0,
        string INVOICE_MOBILE1 = "",
        string INVOICE_EMAIL_ADDRESS = "",
        string INVOICE_PHONE1 = "",
        string INVOICE_POSTAL_CODE = "",
        number INVOICE_STATES_ID = 0,
        number DISCOUNT = 0,
        string DELIVER_NOTES = "",
        string ORDER_NOTES = "",
        boolean isProvisional = false,
        boolean isInvoiceToResellers = false,
        boolean isBilledToBuyingGroup = false,
        number reference_customer = 0,
        string reference_customer_name = "",
        string purchase_order_number = ""
    ) {
        try {
            // Holds final Order object
            var order = {};

            // Sticks current arguments into order object
            structAppend( order, arguments );
            
            // Grabs the company associated with the order
            var company = contactsService.getCompanyByID( companies_ID );
            
            // If there is an account reference and the application is set to generate account references
            if ( 
                !( len( trim( company.account_reference ) ) )
                && application.configuration.generate_account_reference 
            ) {
                // Generate an account reference
                var account_reference = contactsService.generateAccountReference();

                // Update the company's account reference
                application.dao.execute(
                    sql = "UPDATE companies SET account_reference = :accountRef{type='varchar'} WHERE ID = :companyID{type='int'}", 
                    params = {accountRef: account_reference, companyID: companies_ID}
                );
            }

            // Grabs the company's primary contact
            var primaryContact = contactsService.getPrimaryContact( companies_ID );
            // Grabs the primary contact's email address
            var addresses = application.dao.read(
                sql = "SELECT email_address from addresses WHERE ID = :addressID",
                params = {addressID: primaryContact.addresses_ID}
            );
            
            // Sets last needed bits of data for the new order
            order.invoice_email_address = addresses.email_address;
            order.status = 1;
            order.modified_by_users_ID = created_by_users_ID;
            order.modified_datetime = created_datetime = now();
            order.sales_statuses_ID = company.sales_statuses_ID;
            order.sales_status_code = contactsService.getCompanySalesStatusCode( companies_ID );
            
        } catch( any e ) {
            // Error Handline Needed ❌❌❌
            writeDump(e);abort;
        }

        var newID = application.dao.insert(
            table = "orders",
            data = order,
            insertPrimaryKeys = !!val(arguments.ID),
            onFinish = securityService.logEvent,
            callbackArgs = { userID = request.userID, eventType = application.constants.ORDER_ADDED } // ❌ Need to make request.userID
        );

        return newID;
    }

    public void function editOrder( data ) {
        application.dao.update(
            table = "orders",
            data = data, // May re-think this
            onFinish = securityService.logEvent,
            callbackArgs = { userID = request.userID, eventType = application.constants.ORDER_AMENDED} // ❌ Need to make request.userID
        );
    }

    public void function deleteOrder( orderID ) {
        application.dao.update(
            table = "orders",
            data = {
                ID: orderID,
                status: application.constants.STATUS_DELETED
            },
            onFinish = securityService.logEvent,
            callbackArgs = {userID: request.userID, eventType = application.constants.ORDER_DELETED} // ❌ Need to make request.userID
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