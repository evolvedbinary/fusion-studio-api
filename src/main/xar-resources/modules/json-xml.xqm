xquery version "3.1";

(:~ 
 : An implementation of XQuery 3.1's fn:json-to-xml and fn:xml-to-json functions for eXist, which does not support them natively as of 4.3.0.
 : 
 : @author Joe Wicentowski
 : @version 0.4
 : @see http://www.w3.org/TR/xpath-functions-31/#json 
 :)

 (:
 Copied from https://gist.githubusercontent.com/joewiz/d986da715facaad633db/raw/70e29748b2ee6d802a045754d9dd212dcddbb935/json-xml.xqm
 by Adam Retter
 :)
module namespace jx = "http://joewiz.org/ns/xquery/json-xml";

(:~
 : Parses a string supplied in the form of a JSON text, returning the results in the form of an XML document node.
 : 
 : @param  $json-text A string supplied in the form of a JSON text
 : @return  The results in the form of an XML document node
 : @see https://www.w3.org/TR/xpath-functions-31/#func-json-to-xml
 :)
declare function jx:json-to-xml($json-text as xs:string) as document-node()? {
    jx:json-to-xml($json-text, map {})
};

(:~
 : Parses a string supplied in the form of a JSON text, returning the results in the form of an XML document node.
 : 
 : @param  $json-text A string supplied in the form of a JSON text
 : @param  $options Used to control the way in which the parsing takes place
 : @return  The results in the form of an XML document node
 : @see https://www.w3.org/TR/xpath-functions-31/#func-json-to-xml
 :)
declare function jx:json-to-xml($json-text as xs:string, $options as map(*)) as document-node()? {
    let $json := parse-json($json-text, $options)
    return
        document { jx:json-to-xml-recurse($json) }
};

(:~
 : Converts an XML tree, whose format corresponds to the XML representation of JSON defined in the XPath and XQuery 3.1 Functions & Operators specification, into a string conforming to the JSON grammar.
 : 
 : @param  $input An XML tree, whose format corresponds to the XML representation of JSON
 : @return  A string conforming to the JSON grammar
 : @see  https://www.w3.org/TR/xpath-functions-31/#func-xml-to-json
 :)
declare function jx:xml-to-json($input as node()?) as xs:string? {
    jx:xml-to-json($input, map {} )
};

(:~
 : Converts an XML tree, whose format corresponds to the XML representation of JSON defined in the XPath and XQuery 3.1 Functions & Operators specification, into a string conforming to the JSON grammar.
 : 
 : @param  $input An XML tree, whose format corresponds to the XML representation of JSON
 : @param  $options Options for controlling the way in which the conversion takes place
 : @return  A string conforming to the JSON grammar
 : @see  https://www.w3.org/TR/xpath-functions-31/#func-xml-to-json
 :)
declare function jx:xml-to-json($input as node()?, $options as map(*)) as xs:string? {
    let $json := jx:xml-to-json-recurse($input)
    let $serialization-parameters := map { "method": "json", "indent": $options?indent }
    return
        serialize($json, $serialization-parameters)
};

(:~
 : A utility function that recurses through a parsed JSON text, returning the results in the form of XML nodes.
 : 
 : @param  $json A parsed JSON text
 : @return  The results in the form of an XML document node
 :)
declare %private function jx:json-to-xml-recurse($json as item()*) as item()+ {
    let $data-type := jx:json-data-type($json)
    return
        element { QName("http://www.w3.org/2005/xpath-functions", $data-type) } {
            if ($data-type eq "array") then
                for $array-member in $json?*
                let $array-member-data-type := jx:json-data-type($array-member)
                return 
                    element {$array-member-data-type} {
                        if ($array-member-data-type = ("array", "map")) then 
                            jx:json-to-xml-recurse($array-member)/node() 
                        else 
                            $array-member
                    }
            else if ($data-type eq "map") then
                map:for-each(
                    $json, 
                    function($object-name, $object-value) {
                        let $object-value-data-type := jx:json-data-type($object-value)
                        return 
                            element { QName("http://www.w3.org/2005/xpath-functions", $object-value-data-type) } {
                                attribute key {$object-name}, 
                                if ($object-value-data-type = ("array", "map")) then 
                                    jx:json-to-xml-recurse($object-value)/node() 
                                else 
                                    $object-value
                            }
                    }
                )
            else
                $json
        }
};

(:~
 : A utility function for getting the data type of JSON data 
 :)
declare %private function jx:json-data-type($json as item()?) {
    if ($json instance of array(*)) then 'array'
    else if ($json instance of map(*)) then 'map'
    else if ($json instance of xs:string) then 'string'
    else if ($json instance of xs:double) then 'number'
    else if ($json instance of xs:boolean) then 'boolean'
    else if (empty($json)) then 'null'
    else error(xs:QName('ERR'), 'Not a known data type for json data')
};

declare %private function jx:xml-to-json-recurse($input as node()*) as item()* {
    for $node in $input
    return
        typeswitch ($node)
            case element(fn:map) return
                if ($node/@key) then
                    map { $node/@key: map:merge( jx:xml-to-json-recurse($node/node()) ) }
                else
                    map:merge( jx:xml-to-json-recurse($node/node()) )
            case element(fn:array) return
                if ($node/@key) then
                    map { $node/@key: array { jx:xml-to-json-recurse($node/node()) } }
                else
                    array { jx:xml-to-json-recurse($node/node()) }
            case element(fn:string) return
                if ($node/@key) then 
                    map { $node/@key: $node/string() }
                else 
                    $node/string()
            case element(fn:number) return
                if ($node/@key) then
                    map { $node/@key: $node cast as xs:double }
                else 
                    $node cast as xs:double
            case element(fn:boolean) return
                if ($node/@key) then 
                    map { $node/@key: $node cast as xs:boolean }
                else
                    $node cast as xs:boolean
            case element(fn:null) return
                if ($node/@key) then 
                    map { $node/@key: () }
                else
                    'null'
            case document-node() return
                jx:xml-to-json-recurse($node/node())
            (: Comments, processing instructions, and whitespace text node children of map and array are ignored :)
            case text() return 
                if (normalize-space($node) eq '') then 
                    ()
                else
                    $node
            case comment() | processing-instruction() return
                ()
            case element() return
                error(xs:QName('FOJS0006'), 'Invalid XML representation of JSON')
            default return
                error(xs:QName('ERR'), 'Does not match known node types for xml-to-json data')
};