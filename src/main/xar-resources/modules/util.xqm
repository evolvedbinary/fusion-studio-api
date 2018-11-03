xquery version "3.1";

module namespace ut = "http://evolvedbinary.com/ns/pebble/api/util";

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
    replace($path, "(.*)/.*", "$1")
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
    replace($path, ".*/", "")
};
