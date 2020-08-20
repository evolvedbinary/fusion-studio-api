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

module namespace prxq = "http://fusiondb.com/ns/studio/api/restxq";

import module namespace rest = "http://exquery.org/ns/restxq";

declare function prxq:list-by-uri() as array(map(xs:string, xs:string)?) {
    array {
        for $resource-functions in rest:resource-functions()/rest:resource-function
        let $path := "/" || string-join($resource-functions/rest:annotations/rest:path/rest:segment, "/")  
        group by $path
        return
            
            map {
                "uri": $path,
                "methods": array {
                    for $resource-function in $resource-functions
                    return
                        map {
                            "name": $resource-function/rest:annotations/(rest:HEAD|rest:GET|rest:PUT|rest:POST|rest:DELETE)/local-name(.),
                            "function": map {
                                "src": $resource-function/string(@xquery-uri),
                                "name": $resource-function/rest:identity/string-join((@prefix, @local-name), ":") || "#" || $resource-function/rest:identity/string(@arity)
                            } 
                        }
                }
            }
    }
        
};
