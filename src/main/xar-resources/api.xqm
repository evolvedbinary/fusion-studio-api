xquery version "3.1";

module namespace api = "http://evolvedbinary.com/ns/pebble/api";

declare namespace err = "http://www.w3.org/2005/xqt-errors";
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http = "http://expath.org/ns/http-client";

import module namespace config = "http://evolvedbinary.com/ns/pebble/api/config" at "modules/config.xqm";
import module namespace doc = "http://evolvedbinary.com/ns/pebble/api/document" at "modules/document.xqm";
import module namespace exp = "http://evolvedbinary.com/ns/pebble/api/explorer" at "modules/explorer.xqm";
import module namespace jx = "http://joewiz.org/ns/xquery/json-xml" at "modules/json-xml.xqm";
import module namespace perr = "http://evolvedbinary.com/ns/pebble/api/error" at "modules/error.xqm";
import module namespace prxq = "http://evolvedbinary.com/ns/pebble/api/restxq" at "modules/restxq.xqm";


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
    %rest:GET
    %rest:path("/pebble/document")
    %rest:query-param("uri", "{$uri}", "/")
function api:get-document($uri) {
    let $doc := doc:get($uri)
    return
        if (not(empty($doc))) then
            api:cors-allow(
                map {
                    "binary": $doc?binaryDoc, 
                    "headers": map {
                        "Content-Type": $doc?mediaType
                    }
                },
                $doc?content
            )
        else
            api:cors-allow(
                map {
                    "status": 404,
                    "reason": "No such document"
                },
                ()
            )
};

declare
    %rest:PUT("{$body}")
    %rest:path("/pebble/document")
    %rest:header-param("Content-Type", "{$media-type}", "application/octet-stream")
    %rest:query-param("uri", "{$uri}", "/")
function api:put-document($uri, $media-type, $body) {
    if (fn:starts-with($uri, "/db")) then
        try {
            let $doc-uri := doc:put($uri, $media-type, $body)
            return
                api:cors-allow(
                    map {
                        "code": 201,
                        "headers": map {
                            "Content-Location": $doc-uri
                        }
                    },
                    ()
                )
        } catch perr:PD001 {
            api:cors-allow(
                    map {
                        "code": 401,
                        "reason": $err:description
                    },
                    ()
                )
        }
    else
        api:cors-allow(
            map {
                "status": 400,
                "reason": "Document URI must start /db"
            },
            ()
        )
};

declare
    %rest:DELETE
    %rest:path("/pebble/document")
    %rest:query-param("uri", "{$uri}")
function api:delete-document($uri) {
    if (not(empty($uri)) and fn:starts-with($uri, "/db")) then
        try {
            (
                doc:delete($uri),
                api:cors-allow(
                    map {
                        "code": 204
                    },
                    ()
                )
            )
        } catch perr:PD001 {
            api:cors-allow(
                    map {
                        "code": 401,
                        "reason": $err:description
                    },
                    ()
                )
        }
    else
        api:cors-allow(
            map {
                "status": 400,
                "reason": "Document URI must start /db"
            },
            ()
        )
};

declare
    %rest:GET
    %rest:path("/pebble/restxq")
    %rest:produces("application/json")
    %output:method("json")
function api:restxq() {
    api:cors-allow(
        prxq:list-by-uri()
    )
};

declare
    %private
function api:cors-allow($response) {
    api:cors-allow((), $response)
};

declare
    %private
function api:cors-allow($response-ctl as map(xs:string, item())?, $response) {
    (
        <rest:response>
            {
            let $is-binary :=
                if (not(empty($response-ctl?binary)))
                then
                    $response-ctl?binary
                else
                    false()
            return
                if ($is-binary)
                then
                    <output:serialization-parameters>
                        <output:method value="binary"/>
                    </output:serialization-parameters>
                else
                    ()
            }
            <http:response>
                {
                    $response-ctl?code ! attribute status { $response-ctl?code },
                    $response-ctl?reason ! attribute reason { $response-ctl?reason }
                }
                <http:header name="Access-Control-Allow-Origin" value="*"/>
                {
                    if (not(empty($response-ctl?headers))) then
                        map:for-each($response-ctl?headers, function($k,$v) {
                            <http:header name="{$k}" value="{$v}"/>
                        })
                    else ()
                }
            </http:response>
        </rest:response>
        ,
        $response
    )
};
