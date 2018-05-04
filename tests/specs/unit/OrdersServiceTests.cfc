/*******************************************************************************
*	Integration Test as BDD (CF10+ or Railo 4.1 Plus)
*
*	Extends the integration class: coldbox.system.testing.BaseTestCase
*
*	so you can test your ColdBox application headlessly. The 'appMapping' points by default to
*	the '/root' mapping created in the test folder Application.cfc.  Please note that this
*	Application.cfc must mimic the real one in your root, including ORM settings if needed.
*
*	The 'execute()' method is used to execute a ColdBox event, with the following arguments
*	* event : the name of the event
*	* private : if the event is private or not
*	* prePostExempt : if the event needs to be exempt of pre post interceptors
*	* eventArguments : The struct of args to pass to the event
*	* renderResults : Render back the results of the event
*******************************************************************************/
component extends="coldbox.system.testing.BaseTestCase" appMapping="/root"{

	/*********************************** LIFE CYCLE Methods ***********************************/

	function beforeAll(){
		super.beforeAll();
        // do your own stuff here (after super call)
        ordersService = createMock(className="models.services.OrdersService");
	}

	function afterAll(){
		// do your own stuff here (before super call)
		super.afterAll();
	}

/*********************************** BDD SUITES ***********************************/

	function run(){

		describe( "OrdersService", function(){

			beforeEach(function( currentSpec ){
                setup();
			});

            it( "is a valid component", function() {
                expect(ordersService).toBeComponent();
            });

			it( "can add two numbers", function(){
                expect(ordersService.add(1,2)).toBe(3);
            });
			
		});

	}

}