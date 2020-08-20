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

module namespace col = "http://fusiondb.com/ns/studio/api/collection";

import module namespace perr = "http://fusiondb.com/ns/studio/api/error" at "error.xqm";
import module namespace ut = "http://fusiondb.com/ns/studio/api/util" at "util.xqm";

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
                let $_ := xmldb:copy-collection($src-uri, $dst-parent)
                return
                    $dst-uri
            else
                
                (: copy to a temp collection :)
                let $temp-id := util:uuid()
                let $temp-col-uri := ut:mkcol("/db/" || $temp-id)
                let $_ := xmldb:copy-collection($src-uri, $temp-col-uri)
                
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
