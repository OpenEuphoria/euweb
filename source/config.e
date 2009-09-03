/*

	Configuration many times is dependent upon if we are in production or
	development and if in development, who's box is the development being
	done on?

	Thus, each developer of euweb can add their own ifdef, but after the
 	PRODUCTION ifdef and in alpha order for ease of maintenance, please.

	In your own personal EUDIR/eu.cfg add something to the effect of
		-d JEREMY

	This will be used not only with euweb but other Euphoria core projects when
	the need arises to support multiple developer configurations.

	An example config file would be:

	public constant DB_DRIVERS_PATH = "drivers"
	public constant DB_URL = "mysql://user:password@localhost:3306/database_name"
	
	-- Do NOT include the trailing slash
	public constant ROOT_URL = "http://localhost"

	public constant AUTO_LOGIN_UID = 0 -- 0 disables, otherwise set to your UID
	
	-- reCAPTCHA keys
	public constant RECAPTCHA_PRIVATE_KEY = ""
	public constant RECAPTCHA_PUBLIC_KEY = ""

*/

ifdef PRODUCTION then
	public include config_production.e

elsifdef CKL then
	public include dbconfig_ck.e

elsifdef JEREMY then
	public include config_jeremy.e

elsedef
	include std/error.e
	crash("Invalid configuration, please see config.e")

end ifdef
