xquery version "3.1";

module namespace api = "http://evolvedbinary.com/ns/pebble/api";

declare namespace err = "http://www.w3.org/2005/xqt-errors";
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http = "http://expath.org/ns/http-client";
import module namespace sm = "http://exist-db.org/xquery/securitymanager";

import module namespace config = "http://evolvedbinary.com/ns/pebble/api/config" at "modules/config.xqm";
import module namespace col = "http://evolvedbinary.com/ns/pebble/api/collection" at "modules/collection.xqm";
import module namespace doc = "http://evolvedbinary.com/ns/pebble/api/document" at "modules/document.xqm";
import module namespace exp = "http://evolvedbinary.com/ns/pebble/api/explorer" at "modules/explorer.xqm";
import module namespace hsc = "https://tools.ietf.org/html/rfc2616#section-10" at "modules/http-status-codes.xqm";
import module namespace jx = "http://joewiz.org/ns/xquery/json-xml" at "modules/json-xml.xqm";
import module namespace perr = "http://evolvedbinary.com/ns/pebble/api/error" at "modules/error.xqm";
import module namespace prxq = "http://evolvedbinary.com/ns/pebble/api/restxq" at "modules/restxq.xqm";
import module namespace sec = "http://evolvedbinary.com/ns/pebble/api/security" at "modules/security.xqm";
import module namespace ut = "http://evolvedbinary.com/ns/pebble/api/util" at "modules/util.xqm";


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
    %rest:query-param("uri", "{$uri}")
function api:get-document($uri) {
    api:with-valid-uri-ex($uri, function($uri) {
        let $doc := doc:get($uri)
        return
            if (not(empty($doc))) then
                [
                    map {
                        "binary": $doc?binaryDoc, 
                        "headers": map {
                            "Content-Type": $doc?mediaType
                        }
                    },
                    $doc?content
                ]
            else
                [
                    map {
                        "code": $hsc:not-found,
                        "reason": "No such document"
                    },
                    ()
                ]
    })
};

declare
    %rest:PUT("{$body}")
    %rest:path("/pebble/document")
    %rest:header-param("Content-Type", "{$media-type}", "application/octet-stream")
    %rest:query-param("uri", "{$uri}")
    %rest:header-param("x-pebble-copy-source", "{$copy-source}")
    %rest:header-param("x-pebble-move-source", "{$move-source}")
    %rest:produces("application/json")
    %output:method("json")
function api:put-document($uri, $copy-source, $move-source, $media-type, $body) {
    api:with-valid-uri-ex($uri, function($uri) {
        try {
            if ($copy-source) then
                (: COPY :)
                let $doc-uri := doc:copy($copy-source, $uri)
                return
                    [
                        map {
                            "code": $hsc:created,
                            "headers": map {
                                "Content-Location": $doc-uri
                            }
                        },
                        exp:describe($doc-uri)
                    ]
            
            else if ($move-source) then
                (: MOVE :)
                let $doc-uri := doc:move($move-source, $uri)
                return
                    [
                        map {
                            "code": $hsc:created,
                            "headers": map {
                                "Content-Location": $doc-uri
                            }
                        },
                        exp:describe($doc-uri)
                    ]
            else
                (: CREATE :)
                let $doc-uri := doc:put($uri, $media-type, $body)
                return
                    [
                        map {
                            "code": $hsc:created,
                            "headers": map {
                                "Content-Location": $doc-uri
                            }
                        },
                        exp:describe($doc-uri)
                    ]
        } catch perr:PD001 {
            [
                map {
                    "code": $hsc:unauthorized,
                    "reason": $err:description
                },
                ()
            ]
        }
    })
};

declare
    %rest:DELETE
    %rest:path("/pebble/document")
    %rest:query-param("uri", "{$uri}")
function api:delete-document($uri) {
    api:with-valid-uri-ex($uri, function($uri) {
        try {
            [
                map {
                    "code": if (doc:delete($uri)) then $hsc:no-content else $hsc:not-found
                },
                ()
             ]
        } catch perr:PD001 {
            [
                map {
                    "code": $hsc:unauthorized,
                    "reason": $err:description
                },
                ()
            ]
        }
    })
};


declare
    %rest:PUT
    %rest:path("/pebble/collection")
    %rest:query-param("uri", "{$uri}")
    %rest:header-param("x-pebble-copy-source", "{$copy-source}")
    %rest:header-param("x-pebble-move-source", "{$move-source}")
    %rest:produces("application/json")
    %output:method("json")
function api:put-collection($uri, $copy-source, $move-source) {
    api:with-valid-uri-ex($uri, function($uri) {
        try {
            if ($copy-source) then
                (: COPY :)
                let $col-uri := col:copy($copy-source, $uri)
                return
                    [
                        map {
                            "code": $hsc:created,
                            "headers": map {
                                "Content-Location": $col-uri
                            }
                        },
                        exp:describe($col-uri)
                    ]
            
            else if ($move-source) then
                (: MOVE :)
                let $col-uri := col:move($move-source, $uri)
                return
                    [
                        map {
                            "code": $hsc:created,
                            "headers": map {
                                "Content-Location": $col-uri
                            }
                        },
                        exp:describe($col-uri)
                    ]
            
            else
                (: CREATE :)
                let $doc-uri := col:put($uri)
                return
                    [
                        map {
                            "code": $hsc:created,
                            "headers": map {
                                "Content-Location": $doc-uri
                            }
                        },
                        exp:describe($doc-uri)
                    ]
        } catch perr:PD001 {
            [
                map {
                    "code": $hsc:unauthorized,
                    "reason": $err:description
                },
                ()
            ]
        }
    })
};

declare
    %rest:DELETE
    %rest:path("/pebble/collection")
    %rest:query-param("uri", "{$uri}")
function api:delete-collection($uri) {
    api:with-valid-uri-ex($uri, function($uri) {
        try {
            [
                map {
                    "code": if (col:delete($uri)) then $hsc:no-content else $hsc:not-found
                },
                ()
            ]
        } catch perr:PD001 {
            [
                map {
                    "code": $hsc:unauthorized,
                    "reason": $err:description
                },
                ()
            ]
        }
    })
};

declare
    %rest:GET
    %rest:path("/pebble/user")
    %rest:produces("application/json")
    %output:method("json")
function api:list-users() {
    if (ut:is-dba())
    then
        api:cors-allow(
            sec:list-users()
        )
    else
        api:cors-allow(
            map {
                "code": $hsc:unauthorized,
                "reason": "DBA account is required to access user accounts"
            },
            ()
        )
};

declare
    %rest:GET
    %rest:path("/pebble/user/{$username}")
    %rest:produces("application/json")
    %output:method("json")
function api:get-user($username) {
    if (ut:is-dba() or ut:is-current-user($username))
    then
        let $user := sec:get-user($username)
        return
            if (not(empty($user)))
            then
                api:cors-allow($user)
            else
                api:cors-allow(
                    map {
                        "code": $hsc:not-found,
                        "reason": "User account does not exist"
                    },
                    ()
                )
    else
        api:cors-allow(
            map {
                "code": $hsc:unauthorized,
                "reason": "DBA account is required to access other user's account"
            },
            ()
        )
};

declare
    %rest:DELETE
    %rest:path("/pebble/user/{$username}")
    %rest:produces("application/json")
    %output:method("json")
function api:delete-user($username) {
    if (ut:is-current-user($username))
    then
        api:cors-allow(
            map {
                "code": $hsc:conflict,
                "reason": "You cannot delete your own account"
            },
            ()
        )
    else if (ut:is-dba())
    then
        api:cors-allow(
            map {
                "code": if (sec:delete-user($username)) then $hsc:no-content else $hsc:not-found
            },
            ()
        )
    else
        api:cors-allow(
            map {
                "code": $hsc:unauthorized,
                "reason": "DBA account is required to delete other user's account"
            },
            ()
        )
};

declare
    %rest:GET
    %rest:path("/pebble/group")
    %rest:produces("application/json")
    %output:method("json")
function api:list-groups() {
    if (ut:is-dba())
    then
        api:cors-allow(
            sec:list-groups()
        )
    else
        api:cors-allow(
            map {
                "code": $hsc:unauthorized,
                "reason": "DBA account is required to access user groups"
            },
            ()
        )
};

declare
    %rest:GET
    %rest:path("/pebble/group/{$groupname}")
    %rest:produces("application/json")
    %output:method("json")
function api:get-group($groupname) {
    if (ut:is-dba() or ut:is-current-user-member($groupname))
    then
        let $group := sec:get-group($groupname)
        return
            if (not(empty($group)))
            then
                api:cors-allow($group)
            else
                api:cors-allow(
                    map {
                        "code": $hsc:not-found,
                        "reason": "Group does not exist"
                    },
                    ()
                )
    else
        api:cors-allow(
            map {
                "code": $hsc:unauthorized,
                "reason": "DBA account is required to access other group's details"
            },
            ()
        )
};

declare
    %rest:DELETE
    %rest:path("/pebble/group/{$groupname}")
    %rest:produces("application/json")
    %output:method("json")
function api:delete-group($groupname) {
    if (ut:is-current-user-member($groupname))
    then
        api:cors-allow(
            map {
                "code": $hsc:conflict,
                "reason": "You cannot delete a group that you are a member of"
            },
            ()
        )
    else if (ut:is-dba())
    then
        api:cors-allow(
            map {
                "code": if (sec:delete-group($groupname)) then $hsc:no-content else $hsc:not-found
            },
            ()
        )
    else
        api:cors-allow(
            map {
                "code": $hsc:unauthorized,
                "reason": "DBA account is required to delete group"
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
    %rest:OPTIONS
    %rest:produces("text/plain")
function api:explorerOptions() {
    <rest:response>
        <http:response>
            <http:header name="Access-Control-Allow-Origin" value="*"/>
            <http:header name="Access-Control-Max-Age" value="3628800"/>
            <http:header name="Access-Control-Allow-Methods" value="PUT, DELETE, GET, OPTIONS"/>
            <http:header name="Access-Control-Allow-Headers" value="Authorization"/>
        </http:response>
    </rest:response>
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

declare
    %private
function api:with-valid-uri($uri, $f as function(xs:string) as item()*) {
    api:with-valid-uri-ex($uri, function($uri) {
        [
            (),
            $f($uri)
        ]
    })
};

declare
    %private
function api:with-valid-uri-ex($uri, $f as function(xs:string) as array(*)) {
    let $uri := api:valid-db-uri($uri)
    return
        if ($uri)
        then
            let $ctl-and-response := $f($uri)
            return
                api:cors-allow(
                    $ctl-and-response?1,
                    $ctl-and-response?2
                )
        else
            
            api:cors-allow(
                map {
                    "code": $hsc:bad-request,
                    "reason": "URI must start /db"
                },
                ()
            )
};

declare
    %private
function api:valid-db-uri($uri as xs:string*) as xs:string? {
    if (count($uri) eq 1 and fn:starts-with($uri[1], "/db"))
    then
        $uri[1]
    else()
};

