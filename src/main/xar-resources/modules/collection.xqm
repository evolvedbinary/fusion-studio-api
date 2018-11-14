xquery version "3.1";

module namespace col = "http://evolvedbinary.com/ns/pebble/api/collection";

import module namespace perr = "http://evolvedbinary.com/ns/pebble/api/error" at "error.xqm";
import module namespace ut = "http://evolvedbinary.com/ns/pebble/api/util" at "util.xqm";

import module namespace sm = "http://exist-db.org/xquery/securitymanager";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";

declare function col:put($uri as xs:string) as xs:string {
    let $parent-collection-uri := ut:parent-path($uri)
    let $col-name := ut:last-path-component($uri)
    return
        if (sm:has-access(xs:anyURI($parent-collection-uri), "w")) then
            let $new-uri := xmldb:create-collection($parent-collection-uri, $col-name)
            return
                $new-uri
        else
            perr:error($perr:PD001, $uri)
};

declare function col:delete($uri as xs:string) as xs:boolean {
    if (xmldb:collection-available($uri))
    then
        let $parent-collection-uri := ut:parent-path($uri)
        return
            if (sm:has-access(xs:anyURI($uri), "rwx") and sm:has-access(xs:anyURI($parent-collection-uri), "wx"))
            then
                (: delete collection :)
                (
                    xmldb:remove($uri),
                    true()
                )
            else
                perr:error($perr:PD001, $uri)
    else
        false()
};

declare function col:copy($src-uri as xs:string, $dst-uri as xs:string) as xs:string {
    (: check that src exists :)
    if (xmldb:collection-available($src-uri)) then
    
        (: create the parent dst collection if it does not exist :)
        let $src-name := ut:last-path-component($src-uri)
        let $_ :=
            if (xmldb:collection-available($dst-uri)) then
                (
                    $dst-uri,
                    $src-name
                )
            else
                (
                    ut:mkcol(ut:parent-path($dst-uri)),
                    ut:last-path-component($dst-uri)
                )
        let $dst-parent := $_[1]
        let $dst-name := $_[2]
        return
            if ($src-name eq $dst-name) then
                let $_ := xmldb:copy($src-uri, $dst-parent)
                return
                    $dst-uri
            else
                
                (: copy to a temp collection :)
                let $temp-id := util:uuid()
                let $temp-col-uri := ut:mkcol("/db/" || $temp-id)
                let $_ := xmldb:copy($src-uri, $temp-col-uri)
                
                (: rename the collection to its destination name:)
                let $_ := xmldb:rename($temp-col-uri || "/" || $src-name, $dst-name)
                return
    
                    (: move the renamed collection into place :)
                    let $_ := xmldb:move($temp-col-uri || "/" || $dst-name, $dst-parent)
                    
                    (: remove the temp collection :)
                    let $_ := xmldb:remove($temp-col-uri)
                    return
                        
                        $dst-uri
        
    else
        perr:error($perr:PD002, $src-uri)
};

declare function col:move($src-uri as xs:string, $dst-uri as xs:string) as xs:string {
    (: check that src exists :)
    if (xmldb:collection-available($src-uri)) then
    
        (: create the parent dst collection if it does not exist :)
        let $src-name := ut:last-path-component($src-uri)
        let $_ :=
            if (xmldb:collection-available($dst-uri)) then
                (
                    $dst-uri,
                    $src-name
                )
            else
                (
                    ut:mkcol(ut:parent-path($dst-uri)),
                    ut:last-path-component($dst-uri)
                )
        let $dst-parent := $_[1]
        let $dst-name := $_[2]
        return
            if ($src-name eq $dst-name) then
                let $_ := xmldb:move($src-uri, $dst-parent)
                return
                    $dst-uri
            else
                
                (: move to a temp collection :)
                let $temp-id := util:uuid()
                let $temp-col-uri := ut:mkcol("/db/" || $temp-id)
                let $_ := xmldb:move($src-uri, $temp-col-uri)
                
                (: rename the collection to its destination name:)
                let $_ := xmldb:rename($temp-col-uri || "/" || $src-name, $dst-name)
                return
    
                    (: move the renamed collection into place :)
                    let $_ := xmldb:move($temp-col-uri || "/" || $dst-name, $dst-parent)
                    
                    (: remove the temp collection :)
                    let $_ := xmldb:remove($temp-col-uri)
                    return
                        
                        $dst-uri
        
    else
        perr:error($perr:PD002, $src-uri)
};
