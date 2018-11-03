xquery version "3.1";

module namespace api = "http://evolvedbinary.com/ns/pebble/api";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http = "http://expath.org/ns/http-client";

import module namespace config = "http://evolvedbinary.com/ns/pebble/api/config" at "modules/config.xqm";
import module namespace exp = "http://evolvedbinary.com/ns/pebble/api/explorer" at "modules/explorer.xqm";
import module namespace jx = "http://joewiz.org/ns/xquery/json-xml" at "modules/json-xml.xqm";

(: TODO(AR) -
    1. How to properly deal with CORS - see api:cors-allow
    2. How to have a RESTXQ function which produces XML or JSON and chooses the appropriate serializer based on the request?
    3. Do we need sooo much information in the explorer API call, or should we move some info into further API calls?
    4. Explorer API uses ?db= but we should really change this so we use the URI path. How to support unbounded paths in RESTXQ
:)


declare
    %rest:GET
    %rest:path("/pebble/version")
    %rest:produces("application/json")
    %output:method("json")
function api:version() {
    api:cors-allow(
        map {
            "version": $config:version
        }
    )
};

declare
    %rest:GET
    %rest:path("/pebble/explorer")
    %rest:query-param("uri", "{$uri}", "/")
    %rest:produces("application/json")
    %output:method("json")
function api:explorer($uri) {
    api:cors-allow(
        exp:describe($uri)
    )
};

declare
    %private
function api:cors-allow($response) {
    (
        <rest:response>
            <http:response>
                <http:header name="Access-Control-Allow-Origin" value="*"/>
            </http:response>
        </rest:response>
        ,
        $response
    )
};
