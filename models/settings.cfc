component singleton {
    function init() { 
        /** 
        * There will eventually be more setup here with constants that 
        * will get merged into the application scoped flattened constants
        * variable when setApplicationConstants() is called in Application.cfc
        * The same sort of deal is true with application.configuration
        */
        return this; 
    }

    public void function setApplicationConstants() {
        // Gather all the data from the db we want to stick in the flattened constants variable
        var constants = {
            'statuses': application.dao.read(sql='statuses', cachedWithin=createTimeSpan(1,0,0,0), returnType="array"),
            'salesStatuses': application.dao.read(sql="sales_statuses", cachedWithin=createTimeSpan(1,0,0,0), returnType="array"),
            'salesStatusCodes': application.dao.read(sql="SELECT DISTINCT sales_status_code as sys_constant_name FROM companies ORDER BY sales_status_code", cachedWithin=createTimeSpan(1,0,0,0), returnType="array"),
            'orderStatuses': application.dao.read(sql="order_statuses", cachedWithin=createTimeSpan(1,0,0,0), returnType="array"),
            'accountStatuses': application.dao.read(sql="account_statuses", cachedWithin=createTimeSpan(1,0,0,0), returnType="array"),
            'outcomes': application.dao.read(sql="outcomes", cachedWithin=createTimeSpan(1,0,0,0), returnType="array"),
            'eventTypes': application.dao.read(sql="event_types", cachedWithin=createTimeSpan(1,0,0,0), returnType="array"),
            'productTypes': application.dao.read(sql="product_types", cachedWithin=createTimeSpan(1,0,0,0), returnType="array"),
            'productCategories': application.dao.read(sql="product_categories", cachedWithin=createTimeSpan(1,0,0,0), returnType="array"),
            'productPrograms': application.dao.read(sql="product_programs", cachedWithin=createTimeSpan(1,0,0,0), returnType="array"),
            'userTypes': application.dao.read(sql="user_types", cachedWithin=createTimeSpan(1,0,0,0), returnType="array"),
            'activityTypes': application.dao.read(sql="activity_types", cachedWithin=createTimeSpan(1,0,0,0), returnType="array"),
            'paymentTerms': application.dao.read(sql="payment_terms", cachedWithin=createTimeSpan(1,0,0,0), returnType="array"),
            'companyTypes': application.dao.read(sql="company_types", cachedWithin=createTimeSpan(1,0,0,0), returnType="array"),
            'lookupTables': application.dao.read(sql="lookup_tables", cachedWithin=createTimeSpan(1,0,0,0), returnType="array"),
            'salesTaxBasis': application.dao.read(sql="sales_tax_basis", cachedWithin=createTimeSpan(1,0,0,0), returnType="array"),
            'contactTypes': application.dao.read(sql="contact_types", cachedWithin=createTimeSpan(1,0,0,0), returnType="array"),
            'transactionTypes': application.dao.read(sql="transaction_types", cachedWithin=createTimeSpan(1,0,0,0), returnType="array"),
            'invoiceTypes': application.dao.read(sql="invoice_types", cachedWithin=createTimeSpan(1,0,0,0), returnType="array")
        };

        // Get key ready in application scope
        application.constants = {};
        
        // Loop through each key in the data object
        constants.keyArray().each( (key) => {
            // Create a key in the application.constants for each row of data in each key. 
            // This flattens out the data for easier access
            constants[key].each( (value) => {
                // Grabs a correct prefix for certain parentKeys to avoid duplicate keys in the flattened object
                application.constants[getKeyPrefix(key) & safeName(value.sys_constant_name)] = 
                    // We don't use the ID for salesStatusCodes. We use the sys_constant_name instead
                    key == 'salesStatusCodes' ? value.sys_constant_name : value.ID;
            });
        });     
    }

    public void function setApplicationConfiguration() {
        var config = application.dao.read( sql='site_configuration', name='siteConfig');
        var miscConfig = application.dao.read( sql='misc_configuration', name='miscConfig');

        application.configuration = {};

        for (var i = 1; i <= miscConfig.RecordCount; i = i + 1){
            var col = mid(miscConfig['name'][i],6,len(miscConfig['name'][i]));
            application.configuration[col] = miscConfig['misc_configuration_value'][i];
        }
    }

    private string function getKeyPrefix( required string parentKey ) {
        var keyName = "";
        switch( parentKey ) {
            case 'accountStatuses':
                keyName = 'ACCOUNT_STATUS_';
                break;
            case 'productTypes':
                keyName = 'PRODUCT_';
                break;
            case 'productCategories':
                keyName = 'PRODUCT_CATEGORY_';
                break;
            case 'productPrograms':
                keyName = 'PRODUCT_PROGRAM_';
                break;
            case 'userTypes':
                keyName = 'USER_TYPE_';
                break;
            case 'activityTypes':
                keyName = 'ACTIVITY_';
                break;
            case 'paymentTerms':
                keyName = 'PAYMENT_TERM_';
                break;
            case 'lookupTables':
                keyName = 'LOOKUP_TABLE_';
                break;
            case 'transactionTypes':
                keyName = 'TRANSACTION_TYPE_';
                break;
            case 'invoiceTypes':
                keyName= 'INVOICE_TYPE_';
                break;
        }
        return keyName;
    }

    private string function safeName( required string name ) {
        return ucase( ListChangeDelims( trim(name), '_', ' ' ) );
    }
}