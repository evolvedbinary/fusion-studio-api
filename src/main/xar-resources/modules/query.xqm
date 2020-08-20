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

module namespace qry = "http://fusiondb.com/ns/studio/api/query";

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

    let $query :=
        if ($query-data?query-uri)
        then
            let $query-doc := util:binary-doc($query-data?query-uri)
            return
                util:base64-decode($query-doc)
        else
            $query-data?query

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