xquery version "3.1";

module namespace doc = "http://evolvedbinary.com/ns/pebble/api/document";

import module namespace perr = "http://evolvedbinary.com/ns/pebble/api/error" at "error.xqm";
import module namespace ut = "http://evolvedbinary.com/ns/pebble/api/util" at "util.xqm";

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
        if (sm:has-access(xs:anyURI($collection-uri), "w")) then
            let $new-uri := xmldb:store($collection-uri, $doc-name, $body, $media-type)
            return
                $new-uri
        else
            perr:error($perr:PD001, $uri)
};

declare function doc:put-multi($collection-uri as xs:string, $docs as map(xs:string, item())*) as xs:string* {
    for $doc in $docs
    let $filename := $doc?filename
    let $folder-path := ut:parent-path($filename)
    let $doc-name := ut:last-path-component($filename)
    let $collection-uri := if ($folder-path eq $doc-name) then $collection-uri else $collection-uri || "/" || $folder-path
    (: sort into path descending order... optimisation for the collection creation steps :)
    order by fn:tokenize($filename, "/") descending
    return
        let $collection-uri := ut:mkcol($collection-uri)
        return
            if (sm:has-access(xs:anyURI($collection-uri), "w")) then
                xmldb:store($collection-uri, $doc-name, $doc?body)
            else
                perr:error($perr:PD001, $collection-uri || "/" || $doc-name)
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
            
             if ($src-name eq $dst-name) then
                let $_ := xmldb:copy($src-parent, $dst-parent, $src-name)
                return
                    $dst-uri
            else
                
                (: copy to a temp collection :)
                let $temp-id := util:uuid()
                let $temp-col-uri := ut:mkcol("/db/" || $temp-id)
                let $_ := xmldb:copy($src-parent, $temp-col-uri, $src-name)
                
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
                let $_ := xmldb:copy($src-parent, $dst-parent, $src-name)
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
