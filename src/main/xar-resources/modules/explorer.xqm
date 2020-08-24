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

module namespace exp = "http://fusiondb.com/ns/studio/api/explorer";

import module namespace ut = "http://fusiondb.com/ns/studio/api/util" at "util.xqm";

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
function exp:collection-properties($uri) as map(xs:string, xs:string)? {
    (:
        TODO the need for the sm:has-access check below is likely
        a bug. I think reading the properties of the collection should
        not require read access to the collection as the collection
        properties are stored in the Collection entry... check what
        Unix does!

        It seems especially strange... as xmldb:get-child-collections
        is able to read the collection entries without needing
        read access on each collection!
        :)
    if (sm:has-access(xs:anyURI($uri), "r--"))
    then
        map:merge((
            exp:common-resource-properties($uri),
            map {
                "created": xmldb:created($uri)
            }
        ))
    else()
};

declare
    %private
function exp:describe-document($uri) as map(xs:string, item())? {
    (:
    TODO the need for the sm:has-access check below is likely
    a bug. I think reading the properties of the document should
    not require read access to the document as the document
    properties are stored in the Collection entry... check what
    Unix does!

    It seems especially strange... as xmldb:get-child-resources
    is able to read the collection entries without needing
    read access on each document!
    :)
    if (sm:has-access(xs:anyURI($uri), "r--"))
    then
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
    else()
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
