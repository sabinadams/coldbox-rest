component singleton {
    property name="contactsService" inject="services.ContactsService";
    property name="securityService" inject="services.SecurityService";

    function init() { return this; }
    
    // Orders
    public number function addOrder( 
        required number companyID,
        required number USERS_ID,
        required CREATED_BY_USERS_ID,
        required date ORDER_DATETIME,
        required number ORDER_STATUSES_ID,
        required number DELIVER_COMPANIES_ID,
        required string DELIVER_COMPANY,
        required string DELIVER_ADDRESS1,
        required string DELIVER_CITY,
        required string DELIVER_POSTAL_CODE,
        required date DELIVER_DATETIME,
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
        var company = contactsService.getCompanyByID( arguments.companyID );
        
        if ( 
            !( len( trim( company.account_reference ) ) )
            && application.configuration.generate_account_reference 
        ) {
            var account_reference = contactsService.generateAccountReference();
            application.dao.execute(
                sql = "UPDATE companies SET account_reference = :accountRef WHERE ID = :companyID", 
                params = {accountRef: account_reference, companyID: arguments.companyID}
            );
        }
        
        var primaryContact = contactsService.getPrimaryContact( companyID );
        var addresses = application.dao.read(
            sql = "SELECT email_address from addresses WHERE ID = :addressID",
            params = {addressID: primaryContact.addresses_ID}
        );

        arguments.invoice_email_address = addresses.email_address;
        arguments.companies_ID = arguments.companyID;
        arguments.status = 1;
        arguments.modified_by_users_ID = arguments.created_by_users_ID;
        arguments.modified_datetime = arguments.created_datetime = now();
        
        arguments.sales_statuses_ID = company.sales_statuses_ID;
        arguments.sales_status_code = contacts.getCompanySalesStatusCode( arguments.companyID );
        
        var newID = application.dao.insert(
            table = "orders",
            data = order,
            insertPrimaryKeys = arguments.keyExists( 'ID' ),
            logEvent = securityService.logEvent,
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