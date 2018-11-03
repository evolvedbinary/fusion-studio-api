xquery version "3.1";

module namespace api = "http://evolvedbinary.com/ns/pebble/api";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http = "http://expath.org/ns/http-client";

import module namespace config = "http://evolvedbinary.com/ns/pebble/api/config" at "modules/config.xqm";
import module namespace jx = "http://joewiz.org/ns/xquery/json-xml" at "modules/json-xml.xqm";

declare
    %rest:GET
    %rest:path("/pebble/version")
    %rest:produces("application/json")
    %output:method("json")
function api:version() {
    map {
        "version": $config:version
    }
};

declare
    %rest:GET
    %rest:path("/pebble/explorer")
    %rest:produces("application/json")
    %output:method("json")
function api:explorer-root() {
    (
        <rest:response>
            <http:response>
                <http:header name="Access-Control-Allow-Origin" value="*"/>
            </http:response>
        </rest:response>
        ,
        map {
            "collections": [
                map {
                    "uri": "/db",
                    "owner": "adam",
                    "group": "bob",
                    "mode": "rwxrwxrwx"
                }
            ],
            "documents": []
        }
    )
};
