// Necessary to avoid problems with https
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

/*
 * This is a sample configuration file.
 *
 * Copy this file to localsettings.js and edit that file to fit your needs.
 *
 * Also see the file ParserService.js for more information.
 */

exports.setup = function( parsoidConfig ) {
	// The URL of your MediaWiki API endpoint
	//
	// We pre-define wikipedias as 'enwiki', 'dewiki' etc. Similarly for
	// other projects: 'enwiktionary', 'enwikiquote', 'enwikibooks',
	// 'enwikivoyage' etc.
	//
	// Optionally, you can also pass in a proxy specific to this prefix
	// (overrides defaultAPIProxyURI), or null to disable proxying for
	// this end point.

        parsoidConfig.setMwApi({ uri: 'http://localhost/api.php', domain: 'fr.africapack.kiwix.org', prefix: 'fr_africapack' });
 //       parsoidConfig.setMwApi({ uri: 'http://fr.africapack.kiwix.org/w/api.php', domain: 'fr.africapack.kiwix.org', prefix: 'fr_africapack' });

	// A default proxy to connect to the API endpoints. Default: undefined
	// (no proxying). Overridden by per-wiki proxy config in setInterwiki.
	// parsoidConfig.defaultAPIProxyURI = 'http://proxy.example.org:8080';

	// Enable debug mode (prints extra debugging messages)
        // parsoidConfig.debug = true;

	// Use the PHP preprocessor to expand templates via the MW API (default true)
	//parsoidConfig.usePHPPreProcessor = false;

	// Use selective serialization (default false)
        // parsoidConfig.useSelser = true;

	// Allow cross-domain requests to the API (default '*')
	// Sets Access-Control-Allow-Origin header
	// disable:
        parsoidConfig.allowCORS = false;
	// restrict:
	//parsoidConfig.allowCORS = 'some.domain.org';

	// Allow override of port/interface:
	//parsoidConfig.serverPort = 8000;
	//parsoidConfig.serverInterface = '127.0.0.1';

	// The URL of your LintBridge API endpoint
	//parsoidConfig.linterAPI = 'http://lintbridge.wmflabs.org/add';

        // Require SSL certificates to be valid (default true)
        // Set to false when using self-signed SSL certificates
        parsoidConfig.strictSSL = false;
};
