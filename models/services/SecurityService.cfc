component singleton {
    function init() { return this; }

    public function logEvent(
        required any eventType,
        required number userID,
        string remoteIP = '',
        string table = ''
        string screenID = '', // Still needed??
        any ID = '',
        string reference = 'Updated #arguments.ID# in #arguments.table#'
    ) {

    }
}