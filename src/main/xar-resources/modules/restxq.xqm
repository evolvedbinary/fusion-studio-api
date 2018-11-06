xquery version "3.1";

module namespace prxq = "http://evolvedbinary.com/ns/pebble/api/restxq";

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
