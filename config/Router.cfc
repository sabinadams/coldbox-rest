component{

	function configure(){
		setFullRewrites( true );

		// Custom setup
		route( '/data/sample').withAction({
			GET: 'sample',
			POST: 'save'	
		}).toHandler('data');

		// Default setup
		route('/:handler/:action?').end();

	}

}