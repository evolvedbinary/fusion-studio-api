xquery version "3.1";

module namespace exp = "http://evolvedbinary.com/ns/pebble/api/explorer";

import module namespace ut = "http://evolvedbinary.com/ns/pebble/api/util" at "util.xqm";

import module namespace map = "http://www.w3.org/2005/xpath-functions/map";
import module namespace sm = "http://exist-db.org/xquery/securitymanager";
import module namespace util = "http://exist-db.org/xquery/util";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";


declare function exp:describe($uri as xs:string) as map(xs:string, item()) {
    if ($uri eq "/")
    then
        map {
            "collections": [
                exp:collection-properties("/db")
            ],
            "documents": []
        }

    else
        if (xmldb:collection-available($uri))
        then
            exp:describe-collection($uri)
        else
            exp:describe-document($uri)
};

declare
    %private
function exp:describe-collection($uri) as map(xs:string, xs:string) {
    map:merge((
        exp:collection-properties($uri),
        map {
            "collections": array {
                (xmldb:get-child-collections($uri) => sort()) ! exp:collection-properties($uri || "/" || .)

            },
            "documents": array {
                (xmldb:get-child-resources($uri) => sort()) ! exp:describe-document($uri || "/" || .)
            }
        }
    ))
};

declare
    %private
function exp:collection-properties($uri) as map(xs:string, xs:string) {
    map:merge((
        exp:common-resource-properties($uri),
        map {
            "created": xmldb:created($uri)
        }
    ))
};

declare
    %private
function exp:describe-document($uri) as map(xs:string, item()) {
    let $collection-uri := ut:parent-path($uri)
    let $doc-name := ut:last-path-component($uri)

    let $last-modified := xmldb:last-modified($collection-uri, $doc-name)
    let $media-type := xmldb:get-mime-type($uri)
    let $is-binary-doc := util:is-binary-doc($uri)
    let $size := xmldb:size($collection-uri, $doc-name)
    return
        map:merge((
            exp:common-resource-properties($uri),
            map {
                "created": xmldb:created($collection-uri, $doc-name),
                "lastModified": $last-modified,
                "mediaType": $media-type,
                "binaryDoc": $is-binary-doc,
                "size": $size
            }
        ))
};

declare
    %private
function exp:common-resource-properties($uri as xs:string) as map(xs:string, xs:string) {
    let $permissions := sm:get-permissions(xs:anyURI($uri))/sm:permission
    return
        map {
            "uri": $uri,
            "owner": $permissions/@owner,
            "group": $permissions/@group,
            "mode": $permissions/@mode,
            "acl": array {
                $permissions/sm:acl/sm:ace ! exp:describe-ace(.)
            }
        }
};

declare
    %private
function exp:describe-ace($ace as element(sm:ace)) as map(xs:string, xs:string) {
    map {
        "target": $ace/@target,
        "who": $ace/@who,
        "accessType": $ace/@access_type,
        "mode": $ace/@mode
    }
};
