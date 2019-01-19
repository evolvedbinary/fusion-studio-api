xquery version "3.1";

module namespace qry = "http://evolvedbinary.com/ns/pebble/api/query";

declare namespace array = "http://www.w3.org/2005/xpath-functions/array";
import module namespace util = "http://exist-db.org/xquery/util";

(:~
 : Executes the supplied query and serializes the results.
 : 
 : @param $query-data the query and default serialization options
 : @param $start an optional subsequence start
 : @param $length an optional subsequence length
 : 
 : @return the results of the serialized query
 :)
declare function qry:execute($query-data as map(xs:string, xs:string),
        $start as xs:integer?, $length as xs:integer?) as xs:string {
    let $query := $query-data?query
    let $serialization := $query-data?defaultSerialization
    let $eval-ser-fn :=
        if (not(empty($start)) and not(empty($length)))
        then
            util:eval-and-serialize(?, ?, $start, $length)
        else if (not(empty($start)))
        then
            util:eval-and-serialize(?, ?, $start)
        else
            util:eval-and-serialize(?, ?)
    return
        $eval-ser-fn($query, $serialization)
};