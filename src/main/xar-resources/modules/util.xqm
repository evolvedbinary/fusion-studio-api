xquery version "3.1";

module namespace ut = "http://evolvedbinary.com/ns/pebble/api/util";

import module namespace sm = "http://exist-db.org/xquery/securitymanager";
import module namespace util = "http://exist-db.org/xquery/util";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";

(:~
 : Given a path it returns the parent path,
 : that is to say that the last path component
 : is removed from the path.
 :
 : e.g. "/a/b/c/d.xml" -> "/a/b/c"
 :
 : @param path the path to get the parent path from
 :
 : @return the parent path, or the empty sequence if there is no parent
 :)
declare function ut:parent-path($path as xs:string) as xs:string? {
    let $parent := fn:replace($path, "(.*)/.*", "$1")
    return
        if(fn:string-length($parent) gt 0)
        then
            $parent
        else ()
};

(:~
 : Given a path it returns the last component of the path.
 :
 : e.g. "/a/b/c/d.xml" -> "d.xml"
 :
 : @param path the path to get the last path component from
 :
 : @return the last path component
 :)
declare function ut:last-path-component($path as xs:string) as xs:string {
    fn:replace($path, ".*/", "")
};

(:~
 : Gets the head of a sequence
 :
 : @return the head item from the sequence
 :)
declare function ut:head($seq as item()*) as item()? {
    $seq[1]
};

(:~
 : Gets the tail of a sequence
 :
 : @return the tail of the sequence
 :)
declare function ut:tail($seq as item()*) as item()* {
    (: $seq[position() = (2 to fn:count($seq))] :)
    fn:subsequence($seq, 2)
};

(:~
 : Create a Collection in the database (if it doesn't already exist)
 :
 : @param uri the URI of the collection to create
 :
 : @return the URI of the created collection
 :)
declare function ut:mkcol($uri as xs:string) as xs:string {
    let $parts := fn:tokenize(substring-after($uri, "/db"), "/")[fn:string-length(.) gt 0]
    return
        let $_ := ut:_mkcol("/db/" || ut:head($parts), ut:tail($parts))
        return
            $uri
};

(:~
 : Creates a collection path by recursive ascent
 : 
 : @param $current a base collection URI
 : @param $remaining path parts
 : 
 : @return the URIs of collections that were created.
 :)
declare
    %private
function ut:_mkcol($current as xs:string, $remaining as xs:string*) as xs:string* {
    if (not(xmldb:collection-available($current))) then
        xmldb:create-collection(ut:parent-path($current), ut:last-path-component($current))
    else(),

    if ($remaining) then
        ut:_mkcol($current || "/" || ut:head($remaining), ut:tail($remaining))
    else()
};

(:~
 : Returns true if a document is available.
 : 
 : @param $uri the URI of a document
 : 
 : @return true if the document is available, false otherwise.
 :)
declare function ut:doc-available($uri as xs:string ) as xs:boolean {
    fn:doc-available($uri) or util:binary-doc-available($uri)
};

(:~
 : Determines if the current user executing this query is a DBA
 : 
 : @return true if the current user is a DBA
 :)
declare function ut:is-dba() as xs:boolean {
    sm:is-dba(
        sm:id()/sm:id/(sm:effective/sm:username|sm:real/sm:username)[1]
    )
};

(:~
 : Gets the current user
 : 
 : @return a sequence of two strings if setUid is
 : in effect, e.g. (effective-user-name, real-user-name),
 : or just the single string (real-user-name)
 :)
declare function ut:current-user() as xs:string+ {
    sm:id()/sm:id/(sm:effective|sm:real)/sm:username
};

(:~
 : Determines if the user is the user currently executing
 : this query.
 : 
 : @param $username the username of a user
 : 
 : @return true if the $username matches the user currently executing
 :     the query.
 :)
declare function ut:is-current-user($username as xs:string) as xs:boolean {
    ut:current-user() = $username
};

(:~
 : Determines if the user currently executing
 : this query if a member of the group indicated
 : by $groupName.
 : 
 : @param $groupname the name of a group
 : 
 : @return true if the user currently executing
 :     the query is a member of the group.
 :)
declare function ut:is-current-user-member($groupname) as xs:boolean {
    let $username := sm:id()/sm:id/(sm:effective|sm:real)/sm:username
    return
        (sm:get-group-managers($groupname), sm:get-group-members($groupname)) = $username
};

declare function ut:filter-map($map as map(*), $f as function(item(), item()*) as map(*)?) as map(*)? {
    map:merge(
        map:for-each($map, $f)
    )
};

declare function ut:filter-entry-value-empty-sequence($k as item(), $v as item()*) as map(item(), item()*)? {
    
    if (not(empty($v)))
    then
        map {
            $k: $v
        }
    else ()
};
