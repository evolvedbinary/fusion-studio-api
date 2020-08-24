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

module namespace doc = "http://fusiondb.com/ns/studio/api/document";

import module namespace perr = "http://fusiondb.com/ns/studio/api/error" at "error.xqm";
import module namespace ut = "http://fusiondb.com/ns/studio/api/util" at "util.xqm";

import module namespace sm = "http://exist-db.org/xquery/securitymanager";
import module namespace util = "http://exist-db.org/xquery/util";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";

declare function doc:get($uri as xs:string) as map(xs:string, item())? {
    
    if (sm:has-access(xs:anyURI($uri), "r"))
    then
        let $content-fn :=
            if (util:is-binary-doc($uri))
            then
                (true(), util:binary-doc#1)
            else if (fn:doc-available($uri)) then
                (false(), fn:doc#1)
            else
                ()
        return
            if(not(empty($content-fn)))
            then
                map {
                    "mediaType": xmldb:get-mime-type($uri),
                    "binaryDoc": $content-fn[1],
                    "content": $content-fn[2]($uri)
                }
            else
                () 
    else
        () (: TODO(AR) figure out how to differeniate between sm:has-access and fn:doc-available when access is not allowed e.g. perr:error($perr:PD001, $uri) :)
};

declare function doc:put($uri as xs:string, $media-type as xs:string, $body) as xs:string {
    let $collection-uri := ut:parent-path($uri)
    let $doc-name := ut:last-path-component($uri)
    return
        doc:store($collection-uri, $doc-name, $body)
};

declare function doc:put-multi($collection-uri as xs:string, $docs as map(xs:string, item())*) as xs:string* {
    for $doc in $docs
    let $filename := $doc?filename
    let $folder-path := ut:parent-path($filename)
    let $doc-name := ut:last-path-component($filename)
    let $collection-uri := if ($folder-path eq $doc-name) then $collection-uri else $collection-uri || "/" || $folder-path
    (: sort into path descending order... optimisation for the collection creation steps :)
    order by fn:count(fn:tokenize($filename, "/")) descending
    return
        let $collection-uri := ut:mkcol($collection-uri)
        return
            doc:store($collection-uri, $doc-name, $doc?body)
};

declare
    %private
function doc:store($collection-uri as xs:string, $doc-name as xs:string, $content) {
    if (sm:has-access(xs:anyURI($collection-uri), "w")) then

        (: NOTE we don't explicitly specify the media-type from the
        request here, instead we let eXist-db figure it out :)
        
        if (fn:ends-with($doc-name, ".html") or fn:ends-with($doc-name, ".htm")) then
            (: HTML files may be XHTML or just plain HTML. Plain HTML has to be treated as non-XML (Binary) :)
            try {
                (: try as XHTML (XML) :)
                xmldb:store($collection-uri, $doc-name, $content)
            } catch * {
                (: try as plain HTML (Binary) :)
                let $uri := xmldb:store($collection-uri, $doc-name, $content, "application/octet-stream")
                (: Setting a binary document to an XML document mimetype is current forbidden
                 we likely need to update mime-types.xml so that html is binary type :)
                (:
                let $_ := xmldb:set-mime-type($uri, "text/html")
                :)
                return
                    $uri
            }
        else
            xmldb:store($collection-uri, $doc-name, $content)
    else
        perr:error($perr:PD001, $collection-uri || "/" || $doc-name)
};

declare function doc:update-properties($uri as xs:string, $document-properties as map(xs:string, item())) as xs:boolean {
    if (ut:doc-available($uri)) then
        let $collection-uri := ut:parent-path($uri)
        let $doc-name := ut:last-path-component($uri)
        return
            if (sm:has-access(xs:anyURI($uri), "r--")
                and sm:has-access(xs:anyURI($collection-uri), "r-x")
                and ut:is-current-user(sm:get-permissions(xs:anyURI($uri))/sm:permission/@owner))
            then
                (: update document properties :)
                (
                    let $_ :=
                        if ($document-properties?mediaType)
                        then
                            xmldb:set-mime-type(xs:anyURI($uri), $document-properties?mediaType)
                        else()
                    let $_ :=
                        if ($document-properties?mode)
                        then
                            sm:chmod(xs:anyURI($uri), $document-properties?mode)
                        else()
                    let $_ :=
                        if ($document-properties?acl)
                        then
                            let $_ := sm:clear-acl(xs:anyURI($uri))
                            let $_ := array:for-each($document-properties?acl, function($ace) {
                                let $f := if ($ace?target eq "USER")
                                then
                                    sm:add-user-ace#4
                                else
                                    sm:add-group-ace#4
                                return
                                    $f(xs:anyURI($uri), $ace?who, $ace?accessType eq "ALLOWED", $ace?mode)

                            })
                            return
                                ()
                        else()
                    let $_ :=
                        if ($document-properties?group)
                        then
                            sm:chgrp(xs:anyURI($uri), $document-properties?group)
                        else()
                    let $_ :=
                        if ($document-properties?owner)
                        then
                            sm:chown(xs:anyURI($uri), $document-properties?owner)
                        else()
                    return
                        true()
                )
            else
                perr:error($perr:PD001, $uri)
    else
        false()
};

declare function doc:delete($uri as xs:string) as xs:boolean {
    if (ut:doc-available($uri)) then
        let $collection-uri := ut:parent-path($uri)
        let $doc-name := ut:last-path-component($uri)
        return
            if (sm:has-access(xs:anyURI($uri), "rwx") and sm:has-access(xs:anyURI($collection-uri), "wx"))
            then
                (: delete document :)
                (
                    xmldb:remove($collection-uri, $doc-name),
                    true()
                )
            else
                perr:error($perr:PD001, $uri)
    else
        false()
};

declare function doc:copy($src-uri as xs:string, $dst-uri as xs:string) as xs:string {
    (: check that src exists :)
    if (ut:doc-available($src-uri)) then
    
        (: create the parent dst collection if it does not exist :)
        let $src-parent := ut:parent-path($src-uri)
        let $src-name := ut:last-path-component($src-uri)
        let $_ :=
            if (xmldb:collection-available($dst-uri)) then
                (
                    (: copy to existing dest collection :)
                    $dst-uri,
                    ut:last-path-component($src-uri)
                )
            else if (ut:doc-available($dst-uri)) then
                (
                    (: replace existing doc :)
                    ut:parent-path($dst-uri),
                    ut:last-path-component($dst-uri)
                )
            else
                (
                    (: copy to new location :)
                    ut:mkcol(ut:parent-path($dst-uri)),
                    ut:last-path-component($dst-uri)
                )
        let $dst-parent := $_[1]
        let $dst-name := $_[2]
        return
            xmldb:copy-resource($src-parent, $src-name, $dst-parent, $dst-name)

    else
        perr:error($perr:PD003, $src-uri)
};

declare function doc:move($src-uri as xs:string, $dst-uri as xs:string) as xs:string {
    (: check that src exists :)
    if (ut:doc-available($src-uri)) then
    
        (: create the parent dst collection if it does not exist :)
        let $src-parent := ut:parent-path($src-uri)
        let $src-name := ut:last-path-component($src-uri)
        let $_ :=
            if (xmldb:collection-available($dst-uri)) then
                (
                    (: copy to existing dest collection :)
                    $dst-uri,
                    ut:last-path-component($src-uri)
                )
            else if (ut:doc-available($dst-uri)) then
                (
                    (: replace existing doc :)
                    ut:parent-path($dst-uri),
                    ut:last-path-component($dst-uri)
                )
            else
                (
                    (: copy to new location :)
                    ut:mkcol(ut:parent-path($dst-uri)),
                    ut:last-path-component($dst-uri)
                )
        let $dst-parent := $_[1]
        let $dst-name := $_[2]
        return

            if ($src-name eq $dst-name) then
                let $_ := xmldb:move($src-parent, $dst-parent, $src-name)
                return
                    $dst-uri
            else
                
                (: move to a temp collection :)
                let $temp-id := util:uuid()
                let $temp-col-uri := ut:mkcol("/db/" || $temp-id)
                let $_ := xmldb:move($src-parent, $temp-col-uri, $src-name)
                
                (: rename the document to its destination name:)
                let $_ := xmldb:rename($temp-col-uri, $src-name, $dst-name)
                return
    
                    (: move the renamed document into place :)
                    let $_ := xmldb:move($temp-col-uri, $dst-parent, $dst-name)
                    
                    (: remove the temp collection :)
                    let $_ := xmldb:remove($temp-col-uri)
                    return
                        
                        $dst-uri
        
    else
        perr:error($perr:PD003, $src-uri)
};
