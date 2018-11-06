xquery version "3.1";

module namespace doc = "http://evolvedbinary.com/ns/pebble/api/document";

import module namespace perr = "http://evolvedbinary.com/ns/pebble/api/error" at "error.xqm";

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
