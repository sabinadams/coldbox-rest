component singleton {
    function init() { return this; }

    public string function generateAccountReference( boolean displayOnly = false ) {
        var nextRef = "";
        var account_reference = "";
        var unique = false;

        while( !unique ) {
            nextRef = application.dao.read('SELECT counter+1 as next FROM account_reference');
            account_reference = nextRef.next;
            account_reference = "#application.configuration.account_reference_prefix##len(trim(application.configuration.account_reference_mask)) ? numberFormat(account_reference,application.configuration.account_reference_mask) : account_reference#";
            
            if ( !displayOnly ) {
                application.dao.execute(
                    sql="UPDATE account_reference SET counter = :nextValue{type='int'}", 
                    params={nextValue: nextRef.next}
                );
            }

            unique = application.dao.read(
                sql="SELECT ID FROM companies WHERE account_reference = :accountRef{type='varchar'}",
                params={accountRef: account_reference}
            ).recordCount == 0;

            if ( !unique ) {
                application.dao.execute(
                    sql="UPDATE account_reference SET counter = :nextValue{type='int'}",
                    params={nextValue: nextRef.next}
                );
            }
        }

        return account_reference;
    }

    public function getPrimaryContact(
        required number companyID,
        string cachedWithin = '#createTimeSpan(0,1,0,0)#'
    ) {
        var ret = application.dao.read(
            sql = "
                SELECT c.`ID`, companies.`company_types_ID`, c.`name`, c.`title`, c.`contact_types_ID`, c.`created_datetime`,
                c.`created_by_users_ID`, c.`modified_datetime`, c.`modified_by_users_ID`,
                c.`isDecisionMaker`, c.`best_times`, c.`comments`, c.`addresses_ID`
                FROM contacts c
                JOIN companies on companies.primary_contact = c.ID
                WHERE companies.ID = :companyID{type='int'}
            ",
            params = {companyID: companyID},
            name = 'getPrimaryContact_' & companyID,
            cachedWithin = cachedWithin
        );

        return ret;
    }

    public function getCompanySalesStatusCode(
        required number companyID,
        string alias = 'salesStatusCode',
        string toDate = 'CURDATE()',
        string numberOfMonths = application.configuration.SALES_STATUS_MONTHS,
        boolean calculateMonthly = true,
        boolean returnActualMarketShare = false
    ) {
        var sql = getCompanySalesStatusSQL(
            alias = alias,
            pending = false,
            toDate = toDate,
            numberOfMonths = numberOfMonths,
            calculateMonthly = calculateMonthly,
            returnActualMarketShare = returnActualMarketShare
        );

        var calculatedStatus = application.dao.read(
            sql = "#sql# FROM companies WHERE companies.ID = :companyID{type='int'}",
            params={companyID: companyID}
        );

        var salesStatusCode = calculatedStatus[alias];

        if ( !isSimpleValue(salesStatusCode) ) {
            writeDump({
                salesStatusCode: salesStatusCode,
                message: 'Sales Status Code was not a simple value'
            });
            writeOutput("#sql# FROM companies WHERE companies.ID = #companyID#");
            abort;
        }

        if ( returnActualMarketShare ) {
            salesStatusCode = salesStatusCode & "," 
                & val(calculatedStatus.actualMarketShare) & "," 
                & val(calculatedStatus.monthsUsedInCalculation) & "," 
                & val(calculatedStatus.monthQuantity)  & "," 
                & val(calculatedStatus.potentialStrawsPerMonth);
        }

        return JavaCast('string', salesStatusCode);
    }

    public string function getCompanySalesStatusSQL(
        string alias = '',
        boolean includePending = false,
        string toDate = "CURDATE()",
        string numberOfMonths = application.configuration.SALES_STATUS_MONTHS,
        string numberOfMonthsRevertToProspect = application.configuration.SALES_STATUS_PROSPECT_MONTHS,
        boolean calculateMonthly = true,
        boolean returnActualMarketShare = false
    ) {
        
        if ( isDate(toDate) ) toDate = "'#toDate#'";

        var salesStatusCodeSQL = "
            SELECT
            CAST(
                CONCAT(
                    (CASE
                    WHEN IFNULL(NULLIF(herd_size,0),#application.configuration.sales_status_default_herd_size#) >= #application.configuration.large_herd_size# THEN 1
                    -- WHEN IFNULL(NULLIF(herd_size,0),#application.configuration.sales_status_default_herd_size#) <= #application.configuration.small_herd_size# THEN 3 --->
                    ELSE 2 END),

                    (CASE
                    -- New customers, not enough data to calculate true sales status --->
                    WHEN (SELECT count(o.ID)
                            FROM orders o
                            WHERE o.companies_ID = companies.ID
                                AND o.status != #application.constants.STATUS_DELETED#
                                AND o.order_statuses_ID  != #application.constants.ORDER_STATUS_QUOTE#
                                #!includePending ? 'and o.order_statuses_ID IN (#application.constants.ORDER_STATUS_DISPATCHED#,#application.constants.ORDER_STATUS_INVOICED#)' : ''#
                                AND o.deliver_datetime <= #toDate#
                    ) <= 2 AND
                        (SELECT ifNull(FLOOR(DATEDIFF(#toDate#,MIN(o.deliver_datetime))/30),0)
                        FROM orders o
                        WHERE o.companies_ID = companies.ID
                            AND o.status != #application.constants.STATUS_DELETED#
                            AND o.order_statuses_ID  != #application.constants.ORDER_STATUS_QUOTE#
                            #!includePending ? 'and o.order_statuses_ID IN (#application.constants.ORDER_STATUS_DISPATCHED#,#application.constants.ORDER_STATUS_INVOICED#)' : ''#
                            AND o.deliver_datetime <= #toDate#
                        ) <= 1
                    THEN 'N' -- only 1 or less orders 1 or less months ago --->
                    -- Existing Customer - 'A' market share: more than 50% --->
                    WHEN (select sum(oi.original_quantity) /
                            #calculateMonthly ? '
                                (CASE
                                    WHEN (FLOOR(DATEDIFF(#toDate#,MIN(o.deliver_datetime))/30) < #numberOfMonths#
                                            AND  EXISTS (select o2.ID from orders o2
                                                        where o2.companies_ID = o.companies_ID
                                                        AND o2.ID != o.ID
                                                        -- AND o2.deliver_datetime >= #toDate# - INTERVAL #numberOfMonthsRevertToProspect# MONTH --->
                                                        AND o2.deliver_datetime <= #toDate# - INTERVAL #numberOfMonths# MONTH
                                                        AND o2.deliver_datetime < o.deliver_datetime
                                                        ))  THEN
                                        -- There were previous orders --->
                                        #numberOfMonths#
                                    ELSE
                                        -- No previous orders (within x months) --->
                                        FLOOR(DATEDIFF(#toDate#,MIN(o.deliver_datetime))/30)
                                END)' : '#numberOfMonths#'#
                                from order_items oi
                                join orders o on o.ID = oi.orders_ID
                                join products p on p.ID = oi.products_ID
                                -- join companies c on c.ID = o.companies_ID --->
                                where o.companies_ID = companies.ID
                                and o.status != #application.constants.STATUS_DELETED# and oi.status != #application.constants.STATUS_DELETED#
                                and o.order_statuses_ID  != #application.constants.ORDER_STATUS_QUOTE#
                                #!includePending ? 'and o.order_statuses_ID IN (#application.constants.ORDER_STATUS_DISPATCHED#,#application.constants.ORDER_STATUS_INVOICED#)' :''#
                                
                                and p.product_types_ID IN ( select ID from product_types where isSemen = 1 )
                                and o.deliver_datetime >= #toDate# - INTERVAL #numberOfMonths# MONTH
                                #!includePending ? 'and o.deliver_datetime <= #toDate#' : ''#
                                
                            ) -- Got total monthly straws, now divide that by the potential monthly straws: --->
                            / (IF(raisesHeifers,
                                (IFNULL(NULLIF(herd_size,0),#application.configuration.sales_status_default_herd_size#) * #application.configuration.sales_status_straws_needed_heifers#),
                                (IFNULL(NULLIF(herd_size,0),#application.configuration.sales_status_default_herd_size#) * #application.configuration.sales_status_straws_needed_no_heifers#) ) / #numberOfMonths#
                            ) >= .5 THEN 'A'
                    -- Existing Customer - 'B' market share: more 25% to 50% --->
                    WHEN (select sum(oi.original_quantity) /
                            #calculateMonthly ? '
                                (CASE
                                    WHEN (FLOOR(DATEDIFF(#toDate#,MIN(o.deliver_datetime))/30) < #numberOfMonths#
                                            AND  EXISTS (select o2.ID from orders o2
                                                        where o2.companies_ID = o.companies_ID
                                                        AND o2.ID != o.ID
                                                        -- AND o2.deliver_datetime >= #toDate# - INTERVAL #numberOfMonthsRevertToProspect# MONTH --->
                                                        AND o2.deliver_datetime <= #toDate# - INTERVAL #numberOfMonths# MONTH
                                                        AND o2.deliver_datetime < o.deliver_datetime
                                                        ))  THEN
                                        -- There were previous orders --->
                                        #numberOfMonths#
                                    ELSE
                                        -- No previous orders (within x months) --->
                                        FLOOR(DATEDIFF(#toDate#,MIN(o.deliver_datetime))/30)
                                END)' : '#numberOfMonths#'#
                                from order_items oi
                                join orders o on o.ID = oi.orders_ID
                                join products p on p.ID = oi.products_ID
                                -- join companies c on c.ID = o.companies_ID --->
                                where o.companies_ID = companies.ID
                                and o.status != #application.constants.STATUS_DELETED# and oi.status != #application.constants.STATUS_DELETED#
                                and o.order_statuses_ID  != #application.constants.ORDER_STATUS_QUOTE#
                                #!includePending ? 'and o.order_statuses_ID IN (#application.constants.ORDER_STATUS_DISPATCHED#,#application.constants.ORDER_STATUS_INVOICED#)' : ''#
                                and p.product_types_ID IN ( select ID from product_types where isSemen = 1 )
                                and o.deliver_datetime >= #toDate# - INTERVAL #numberOfMonths# MONTH
                                #!includePending ? 'and o.deliver_datetime <= #toDate#' : ''#
                                
                            ) -- Got total monthly straws, now divide that by the potential monthly straws: --->
                            / ( IF(raisesHeifers,
                                (IFNULL(NULLIF(herd_size,0),#application.configuration.sales_status_default_herd_size#) * #application.configuration.sales_status_straws_needed_heifers#),
                                (IFNULL(NULLIF(herd_size,0),#application.configuration.sales_status_default_herd_size#) * #application.configuration.sales_status_straws_needed_no_heifers#) ) / #numberOfMonths#
                                ) between .26 and .5 THEN 'B'
                    -- Existing Customer - 'C' market share: less than 25% --->
                    WHEN ((select max(o1.deliver_datetime) from orders o1
                            where o1.companies_ID = companies.ID
                            and o1.order_statuses_ID  != #application.constants.ORDER_STATUS_QUOTE#
                            #!includePending ? 'and o1.order_statuses_ID IN (#application.constants.ORDER_STATUS_DISPATCHED#,#application.constants.ORDER_STATUS_INVOICED#)' : ''#
                            
                            and o1.status !=  #application.constants.STATUS_DELETED#)) is not null THEN 'C'
                    -- Prospect - 'P' market share: 0% (never ordered) --->
                    ELSE 'P' END),

                    -- Determine if customer is 'i': irregular (hasn't purchased frequent enough) --->
                    (
                        IF ( (select max(o.deliver_datetime) from orders o
                        where o.companies_ID = companies.ID
                        and o.order_statuses_ID  != #application.constants.ORDER_STATUS_QUOTE#
                        #!includePending ? 'and o.order_statuses_ID IN (#application.constants.ORDER_STATUS_DISPATCHED#,#application.constants.ORDER_STATUS_INVOICED#)' : ''#
                        
                        and o.status !=  #application.constants.STATUS_DELETED#) >= #toDate# - INTERVAL #application.configuration.sales_status_lapsed_months# MONTH
                    ,-- then --->
                        IF ( (select COUNT(*) from orders o where companies_ID = companies.ID
                            and order_statuses_ID  != #application.constants.ORDER_STATUS_QUOTE#
                            #!includePending ? 'and order_statuses_ID IN (#application.constants.ORDER_STATUS_DISPATCHED#,#application.constants.ORDER_STATUS_INVOICED#)' : ''#

                            and o.deliver_datetime >= #toDate# - INTERVAL #application.configuration.sales_status_lapsed_months# MONTH
                            #!includePending ? 'and o.deliver_datetime <= #toDate#' : ''#
                        ) = 0
                        ,-- then --->
                            'i'
                        ,-- else --->
                            ''
                        )

                    ,-- else --->
                        'i')
                    ) )
                    as CHAR) #len(trim(alias)) ? 'as #alias#' : ''#
                    #returnActualMarketShare ? '#"
                    , (select sum(oi.original_quantity) /
                    -- <cfif calculateMonthly>FLOOR(DATEDIFF(#toDate#,MIN(o.deliver_datetime))/30)<cfelse>#numberOfMonths#</cfif>  --->
                            #calculateMonthly ? '
                                (CASE
                                    WHEN (FLOOR(DATEDIFF(#toDate#,MIN(o.deliver_datetime))/30) < #numberOfMonths#
                                            AND  EXISTS (select o2.ID from orders o2
                                                        where o2.companies_ID = o.companies_ID
                                                        AND o2.ID != o.ID
                                                        -- AND o2.deliver_datetime >= #toDate# - INTERVAL #numberOfMonthsRevertToProspect# MONTH --->
                                                        AND o2.deliver_datetime <= #toDate# - INTERVAL #numberOfMonths# MONTH
                                                        AND o2.deliver_datetime < o.deliver_datetime
                                                        ))  THEN
                                        -- There were previous orders --->
                                        #numberOfMonths#
                                    ELSE
                                        -- No previous orders (within x months) --->
                                        FLOOR(DATEDIFF(#toDate#,MIN(o.deliver_datetime))/30)
                                END) ' : '#numberOfMonths#'#
                                from order_items oi
                                join orders o on o.ID = oi.orders_ID
                                join products p on p.ID = oi.products_ID
                                where o.companies_ID = companies.ID
                                and o.status != #application.constants.STATUS_DELETED# and oi.status != #application.constants.STATUS_DELETED#
                                and o.order_statuses_ID  != #application.constants.ORDER_STATUS_QUOTE#
                                #!includePending ? 'and o.order_statuses_ID IN (#application.constants.ORDER_STATUS_DISPATCHED#,#application.constants.ORDER_STATUS_INVOICED#)' : ''#
                                and p.product_types_ID IN ( select ID from product_types where isSemen = 1 )
                                and o.deliver_datetime >= #toDate# - INTERVAL #numberOfMonths# MONTH
                                #!includePending ? 'and o.deliver_datetime <= #toDate#' : ''#
                                
                            )  -- Got total monthly straws, now divide that by the potential monthly straws: --->
                            / ( IF(raisesHeifers,
                                (IFNULL(NULLIF(herd_size,0),#application.configuration.sales_status_default_herd_size#) * #application.configuration.sales_status_straws_needed_heifers#),
                                (IFNULL(NULLIF(herd_size,0),#application.configuration.sales_status_default_herd_size#) * #application.configuration.sales_status_straws_needed_no_heifers#) ) / #numberOfMonths#
                            ) as actualMarketShare,

                                /*
                                    NOTES:
                                    Time frame logic
                                    if earliest order is less than numberOfMonths months ago and a prior order exists within y months
                                            numberOfMonths
                                    else
                                        earliest order
                                    end
                                    */
                                (SELECT (CASE
                                    WHEN (FLOOR(DATEDIFF(#toDate#,MIN(o.deliver_datetime))/30) < #numberOfMonths#
                                            AND  EXISTS (select o2.ID from orders o2
                                                        where o2.companies_ID = o.companies_ID
                                                        AND o2.ID != o.ID
                                                        -- AND o2.deliver_datetime >= #toDate# - INTERVAL #numberOfMonthsRevertToProspect# MONTH --->
                                                        AND o2.deliver_datetime <= #toDate# - INTERVAL #numberOfMonths# MONTH
                                                        AND o2.deliver_datetime < o.deliver_datetime
                                                        ))  THEN
                                        -- There were previous orders --->
                                        #numberOfMonths#
                                    ELSE
                                        -- No previous orders (within x months) --->
                                        FLOOR(DATEDIFF(#toDate#,MIN(o.deliver_datetime))/30)
                                END)

                                from order_items oi
                                join orders o on o.ID = oi.orders_ID
                                join products p on p.ID = oi.products_ID
                                where o.companies_ID = companies.ID
                                and o.status != #application.constants.STATUS_DELETED# and oi.status != #application.constants.STATUS_DELETED#
                                and o.order_statuses_ID  != #application.constants.ORDER_STATUS_QUOTE#
                                <cfif not includePending>
                                    and o.order_statuses_ID IN (#application.constants.ORDER_STATUS_DISPATCHED#,#application.constants.ORDER_STATUS_INVOICED#)
                                </cfif>
                                and p.product_types_ID IN ( select ID from product_types where isSemen = 1 )
                                and o.deliver_datetime >= #toDate# - INTERVAL #numberOfMonths# MONTH
                                <cfif not includePending>
                                    and o.deliver_datetime <= #toDate#
                                </cfif>
                                ) as monthsUsedInCalculation,
                            -- Monthly Straws --->
                            (select (
                                sum(oi.original_quantity)
                                / -- Divide by number of --->
                                #calculateMonthly ? '
                                    (CASE
                                        WHEN (FLOOR(DATEDIFF(#toDate#,MIN(o.deliver_datetime))/30) < #numberOfMonths#
                                                AND  EXISTS (select o2.ID from orders o2
                                                            where o2.companies_ID = o.companies_ID
                                                            AND o2.ID != o.ID
                                                            -- AND o2.deliver_datetime >= #toDate# - INTERVAL #numberOfMonthsRevertToProspect# MONTH --->
                                                            AND o2.deliver_datetime <= #toDate# - INTERVAL #numberOfMonths# MONTH
                                                            AND o2.deliver_datetime < o.deliver_datetime
                                                            ))  THEN
                                            -- There were previous orders --->
                                            #numberOfMonths#
                                        ELSE
                                            -- No previous orders (within x months) --->
                                            FLOOR(DATEDIFF(#toDate#,MIN(o.deliver_datetime))/30)
                                    END) ' : '#numberOfMonths#'#
                                )
                                    from order_items oi
                                    join orders o on o.ID = oi.orders_ID
                                    join products p on p.ID = oi.products_ID
                                    where o.companies_ID = companies.ID
                                    and o.status != #application.constants.STATUS_DELETED# and oi.status != #application.constants.STATUS_DELETED#
                                    and o.order_statuses_ID  != #application.constants.ORDER_STATUS_QUOTE#
                                    #!includePending ? 'and o.order_statuses_ID IN (#application.constants.ORDER_STATUS_DISPATCHED#,#application.constants.ORDER_STATUS_INVOICED#)' :''#
                                    and p.product_types_ID IN ( select ID from product_types where isSemen = 1 )
                                    and o.deliver_datetime >= #toDate# - INTERVAL #numberOfMonths# MONTH
                                    #!includePending ? 'and o.deliver_datetime <= #toDate#' : ''#)

                            as monthQuantity,
                            ( IF(raisesHeifers,
                                (IFNULL(NULLIF(herd_size,0),#application.configuration.sales_status_default_herd_size#) * #application.configuration.sales_status_straws_needed_heifers#),
                                (IFNULL(NULLIF(herd_size,0),#application.configuration.sales_status_default_herd_size#) * #application.configuration.sales_status_straws_needed_no_heifers#) ) / #numberOfMonths#
                            ) as potentialStrawsPerMonth
                                "#' : ''#
            -- FROM companies --->
        ";
        
        return salesStatusCodeSQL;
    }

    public array function getCompanyByID(number companyID = 0, any cachedWithin = createTimeSpan(0,0,0,0)) {
        // Used to have a LIMIT 0 instead of the where clause if no companyID or invalid companyID        
        var ret = application.dao.read( 
            sql = "
                SELECT c.`ID`, c.`company_types_ID`, c.`account_statuses_ID`, c.`sales_statuses_ID`, c.`users_ID`, c.`secondary_users_ID`, c.`buying_groups_ID`, c.`reseller_companies_ID`,
                c.`name`,c.`search_name`,c.`ubn_number`,c.`vat_registration_number`, c.`primary_contact`,pc.name as primary_contact_name, c.`addresses_ID`, c.`shipping_addresses_ID`, c.`account_reference`, c.`route_user_reference_code`,c.`route_territory`, c.`generated_route_code`, c.`route_number`, c.`route_stop_number`,
                c.`contact_next_datetime`, c.`isAppointment`, c.`comments`, c.`password`, c.`activation_code`,
                c.`herd_size`, c.`raisesHeifers`, c.`usesWMS`, c.`calving_pattern`, c.`email_opt_out`,  a.`email_address`,a.`email_address2`, c.`isHot`, c.`status`,
                c.`ytd_straws`, c.`created_by_users_ID`, c.`created_datetime`, c.`modified_by_users_ID`,
                c.`modified_datetime`, c.`custom_text_1`, c.`custom_text_2`, c.`custom_text_3`, c.`custom_text_4`,
                c.`custom_text_5`, c.`custom_int_1`, c.`custom_int_2`, c.`custom_int_3`, c.`custom_int_4`, c.`custom_int_5`,
                c.`custom_boolean_1`, c.`custom_boolean_2`, c.`custom_boolean_3`, c.`custom_boolean_4`,
                c.`custom_boolean_5`, c.`custom_datetime_1`, c.`custom_datetime_2`, c.`custom_datetime_3`,
                c.`custom_datetime_4`, c.`custom_datetime_5`, c.`ai_services_ID`, c.`priorities_1`, c.`priorities_2`,
                c.`priorities_3`, c.`priorities_4`, c.`priorities_5`, c.`priorities_6`,c.`isExported`,c.`exported_datetime`,
                c.`exported_batch_number`,c.`campaigns_completed`, c.`do_not_call`, c.default_payment_terms, c.default_contact_frequency, pt.name as payment_terms_name,
                c.tax_auth_code, c.locales_ID, c.`default_locations_ID`, a.`ID` as addressID, a.`address1`, a.`address2`,a.`address3`, a.`address4`,a.`address5`,a.`address6`, a.`city`,
                a.`postal_code`, a.`country_name`,a.`countries_ID`, a.`counties_ID`, a.`states_ID`,
                a.`phone1`, a.`phone2`, a.`mobile1`, a.`mobile2`, a.`office1`, a.`office2`, a.`fax1`, a.`fax2`,
                a.`address_timezone`, a.`address_name` as address_name, c.`tax_auth_code`,
                counties.alpha_ISO_code as county_alpha_iso_code, counties.county_name, states.abbreviation as state_abbreviation, states.state as state_name, states.state,
                ai.name as ai_service,ai.isDiy, l.locale
                FROM companies c
                JOIN contacts pc on pc.ID = c.primary_contact
                JOIN addresses a on a.ID = c.addresses_ID
                LEFT JOIN counties on counties.ID = a.counties_ID
                LEFT JOIN states on states.ID = a.states_ID
                LEFT JOIN payment_terms pt on pt.ID = c.default_payment_terms
                LEFT JOIN ai_services ai on ai.ID = c.ai_services_ID
                LEFT JOIN locales l on l.ID = c.locales_ID
                WHERE c.ID = :companyID{type='int'}
            ",
            params = {companyID: companyID},
            name = 'getCompanyByID_' & companyID != 0 ? companyID : 'structure',
            cachedWithin = cachedWithin,
            returnType = "array"
        );
        
        return ret;
    }
}