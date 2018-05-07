component{

	function configure(){
		setFullRewrites( true );

		// Custom setup
		// route( '/orders/').withAction({
		// 	GET: 'sample',
		// 	POST: 'save'	
		// }).toHandler('orders');

		// Default setup
		route('/:handler/:action?').end();

	}

}