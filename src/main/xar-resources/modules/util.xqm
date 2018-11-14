xquery version "3.1";

module namespace ut = "http://evolvedbinary.com/ns/pebble/api/util";

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
: @return the parent path
:)
declare function ut:parent-path($path as xs:string) as xs:string {
    fn:replace($path, "(.*)/.*", "$1")
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

declare function ut:doc-available($uri as xs:string ) as xs:boolean {
    fn:doc-available($uri) or util:binary-doc-available($uri)
};