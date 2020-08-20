(:
 : Fusion Studio API - API for Fusion Studio
 : Copyright © 2017 Evolved Binary (tech@evolvedbinary.com)
 :
 : This program is free software: you can redistribute it and/or modify
 : it under the terms of the GNU Affero General Public License as published by
 : the Free Software Foundation, either version 3 of the License, or
 : (at your option) any later version.
 :
 : This program is distributed in the hope that it will be useful,
 : but WITHOUT ANY WARRANTY; without even the implied warranty of
 : MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 : GNU Affero General Public License for more details.
 :
 : You should have received a copy of the GNU Affero General Public License
 : along with this program.  If not, see <http://www.gnu.org/licenses/>.
 :)
xquery version "3.1";

module namespace api = "http://fusiondb.com/studio/api";

declare namespace err = "http://www.w3.org/2005/xqt-errors";
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http = "http://expath.org/ns/http-client";
import module namespace sm = "http://exist-db.org/xquery/securitymanager";
import module namespace system = "http://exist-db.org/xquery/system";

import module namespace config = "http://fusiondb.com/ns/studio/api/config" at "modules/config.xqm";
import module namespace col = "http://fusiondb.com/ns/studio/api/collection" at "modules/collection.xqm";
import module namespace doc = "http://fusiondb.com/ns/studio/api/document" at "modules/document.xqm";
import module namespace exp = "http://fusiondb.com/ns/studio/api/explorer" at "modules/explorer.xqm";
import module namespace hsc = "https://tools.ietf.org/html/rfc2616#section-10" at "modules/http-status-codes.xqm";
import module namespace idx = "http://fusiondb.com/ns/studio/api/index" at "modules/index.xqm";
import module namespace jx = "http://joewiz.org/ns/xquery/json-xml" at "modules/json-xml.xqm";
import module namespace mul = "http://fusiondb.com/ns/studio/api/multipart" at "modules/multipart.xqm";
import module namespace perr = "http://fusiondb.com/ns/studio/api/error" at "modules/error.xqm";
import module namespace prxq = "http://fusiondb.com/ns/studio/api/restxq" at "modules/restxq.xqm";
import module namespace qry = "http://fusiondb.com/ns/studio/api/query" at "modules/query.xqm";
import module namespace sec = "http://fusiondb.com/ns/studio/api/security" at "modules/security.xqm";
import module namespace ut = "http://fusiondb.com/ns/studio/api/util" at "modules/util.xqm";


(: TODO(AR) -
    1. How to properly deal with CORS - see api:cors-allow
    2. How to have a RESTXQ function which produces XML or JSON and chooses the appropriate serializer based on the request?
    3. Do we need sooo much information in the explorer API call, or should we move some info into further API calls?
    4. Explorer API uses ?db= but we should really change this so we use the URI path. How to support unbounded paths in RESTXQ?
:)


declare
    %rest:GET
    %rest:path("/fusiondb/version")
    %rest:produces("application/json")
    %output:method("json")
function api:version() {
    api:cors-allow(
        map {
            "version": $config:version,
            "server": map {
                "product-name": system:get-product-name(),
                "version": system:get-version(),
                "revision": system:get-revision(),
                "build": system:get-build()
            }
        }
    )
};

declare
    %rest:GET
    %rest:path("/fusiondb/explorer")
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
    %rest:path("/fusiondb/document")
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
    %rest:path("/fusiondb/document")
    %rest:header-param("Content-Type", "{$media-type}", "application/octet-stream")
    %rest:query-param("uri", "{$uri}")
    %rest:header-param("x-fs-copy-source", "{$copy-source}")
    %rest:header-param("x-fs-move-source", "{$move-source}")
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
            else if (starts-with($media-type, "multipart/form-data")) then
               (: CREATE multiple files :)
               let $boundary := fn:substring-after($media-type, "boundary=")
               let $parts := mul:extract-parts($boundary, $body)
               let $file-parts := mul:file-parts($parts)
               let $files :=
                    for $file-part in $file-parts
                    return
                        map:merge(map:for-each($file-part, function($k, $v) {
                            if ($k eq "body") then
                                map:entry($k, $v)
                            else if ($k eq "headers") then
                                (
                                for $cd-header in $v[?name eq "Content-Disposition"]
                                return
                                    map:entry("filename", replace($cd-header?value, '.*filename="(.+)".*', "$1"))
                                ,
                                for $cd-header in $v[?name eq "Content-Type"]
                                return
                                    map:entry("media-type", $cd-header?value)
                                )
                            else ()
                        }))
               return
                   let $doc-uris := doc:put-multi($uri, $files)
                   return
                        [
                            map {
                                "code": $hsc:created,
                                "headers": map {
                                    "Content-Location": $uri
                                }
                            },
                            array {
                                $doc-uris ! exp:describe(.)
                            }
                        ]
                   
            else
                (: CREATE single file :)
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
    %rest:path("/fusiondb/document")
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
    %rest:path("/fusiondb/collection")
    %rest:query-param("uri", "{$uri}")
    %rest:header-param("x-fs-copy-source", "{$copy-source}")
    %rest:header-param("x-fs-move-source", "{$move-source}")
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
    %rest:path("/fusiondb/collection")
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
    %rest:path("/fusiondb/user")
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
    %rest:path("/fusiondb/user/{$username}")
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
    %rest:PUT("{$body}")
    %rest:path("/fusiondb/user/{$username}")
    %rest:consumes("application/json")
    %rest:produces("application/json")
    %output:method("json")
function api:put-user($username, $body) {
    if (empty($body))
    then
        api:cors-allow(
            map {
                "code": $hsc:bad-request,
                "reason": "Missing request body"
            },
            ()
        )
    else if (ut:is-dba() or ut:is-current-user($username))
    then
        api:cors-allow(
            let $json-txt := util:base64-decode($body)
            let $user-data := fn:parse-json($json-txt)
            return
                map {
                    "code": if (sec:put-user($username, $user-data)) then $hsc:no-content else $hsc:bad-request
                },
                ()
        )
    else
        api:cors-allow(
            map {
                "code": $hsc:unauthorized,
                "reason": "DBA account is required to Create/Modify another user account"
            },
            ()
        )
};

declare
    %rest:DELETE
    %rest:path("/fusiondb/user/{$username}")
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
    %rest:path("/fusiondb/group")
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
    %rest:path("/fusiondb/group/{$groupname}")
    %rest:produces("application/json")
    %output:method("json")
function api:get-group($groupname) {
    if (ut:is-dba() or ut:is-current-user-member-or-manager($groupname))
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
    %rest:PUT("{$body}")
    %rest:path("/fusiondb/group/{$groupname}")
    %rest:consumes("application/json")
    %rest:produces("application/json")
    %output:method("json")
function api:put-group($groupname, $body) {
    if (empty($body))
    then
        api:cors-allow(
            map {
                "code": $hsc:bad-request,
                "reason": "Missing request body"
            },
            ()
        )
    else if (ut:is-dba() or ut:is-current-user-manager($groupname))
    then
        api:cors-allow(
            let $json-txt := util:base64-decode($body)
            let $group-data := fn:parse-json($json-txt)
            return
                map {
                    "code": if (sec:put-group($groupname, $group-data)) then $hsc:no-content else $hsc:bad-request
                },
                ()
        )
    else
        api:cors-allow(
            map {
                "code": $hsc:unauthorized,
                "reason": "DBA account is required to Create/Modify another user group"
            },
            ()
        )
};

declare
    %rest:DELETE
    %rest:path("/fusiondb/group/{$groupname}")
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
    else if (ut:is-dba() or ut:is-current-user-manager($groupname))
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
    %rest:path("/fusiondb/index")
    %rest:query-param("uri", "{$uri}")
    %rest:produces("application/json")
    %output:method("json")
function api:get-index($uri) {
        if (empty($uri))
        then
            api:cors-allow(
                idx:list-explicit()
            )
        else
            let $index := idx:get-implicit($uri)
            return
                if (not(empty($index)))
                then
                    api:cors-allow($index)
                else
                    api:cors-allow(
                        map {
                            "code": $hsc:not-found
                        },
                        ()
                    )
};

declare
    %rest:GET
    %rest:path("/fusiondb/restxq")
    %rest:produces("application/json")
    %output:method("json")
function api:restxq() {
    api:cors-allow(
        prxq:list-by-uri()
    )
};


declare
    %rest:POST("{$body}")
    %rest:path("/fusiondb/query")
    %rest:header-param("Range", "{$range-header}")
    %rest:consumes("application/json")
    %rest:produces("application/json")
    %output:method("json")
function api:query($range-header, $body) {
    if (empty($body))
    then
        api:cors-allow(
            map {
                "code": $hsc:bad-request,
                "reason": "Missing request body"
            },
            ()
        )
    else if (ut:is-guest())
    then
        api:cors-allow(
            map {
                "code": $hsc:forbidden,
                "reason": "Guest is not allowed to execute arbitary queries"
            },
            ()
        )
    else
        let $json-txt := util:base64-decode($body)
        let $query-data := fn:parse-json($json-txt)
        return
            let $range :=
                if (fn:empty($range-header) or fn:not(fn:starts-with($range-header, "items=")))
                then
                    ()
                else
                    let $res := fn:analyze-string($range-header, "items=([0-9]+)-([0-9]+)?")
                    return
                        ($res//fn:group[@nr eq "1"]/xs:integer(.), $res//fn:group[@nr eq "2"]/xs:integer(.))
            
            let $query-results := qry:execute($query-data, $range[1], $range[2])
            
            let $content-range-header :=
                if (not(empty($range)))
                then
                    map {
                        "Content-Range": "items " || $range[1] || "-" || count($query-results) || "/*"
                    }
                else
                    map {}
            return
                api:cors-allow(
                    map {
                        "code": if (not(empty($range))) then $hsc:partial-content else $hsc:ok,
                        "headers": map:merge((map {
                            "Accept-Ranges": "items"
                        }, $content-range-header))
                    },
                    map {
                        "results": $query-results
                    }
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
            <http:header name="Access-Control-Allow-Methods" value="PUT, POST, DELETE, GET, OPTIONS"/>
            <http:header name="Access-Control-Allow-Headers" value="Authorization, Content-Type, x-fs-copy-source, x-fs-move-source, Range"/>
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

