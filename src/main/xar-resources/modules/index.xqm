xquery version "3.1";

module namespace idx = "http://evolvedbinary.com/ns/pebble/api/index";

declare namespace cc = "http://exist-db.org/collection-config/1.0";

import module namespace ut = "http://evolvedbinary.com/ns/pebble/api/util" at "util.xqm";

declare function idx:list-explicit() as xs:string* {
    (: Note: the predicate filters out index definitons which only mention the old legacy full-text index :)
    for $index in fn:collection("/db/system/config")//cc:index[child::element()[local-name(.) ne "fulltext"]]
    return
        fn:substring-after(ut:parent-path(document-uri(root($index))), "/db/system/config")
};

declare function idx:get-implicit($uri as xs:string) as map(xs:string, item())? {
    let $index := idx:get-configured-index($uri)
    return
        if ($index)
        then
            ut:filter-map (
                map {
                    "uri": $uri,
                    "lucene": idx:lucene-index($index/cc:lucene),
                    "range": idx:range-index($index/cc:range),
                    "ngram": idx:ngram-index($index/cc:ngram),
                    "legacy-range": idx:legacy-range-index($index/cc:create)
                }
                ,
                ut:filter-entry-value-empty-sequence#2
            )
        else()
};

declare
    %private
function idx:lucene-index($lucene as element(cc:lucene)?) as map(xs:string, item())? {
    if ($lucene)
    then
        map {
            "analyzers": array {
                $lucene/cc:analyzer ! ut:filter-map(
                    map {
                        "id": xs:string(@id),
                        "class": xs:string(@class),
                        "params": array {
                            cc:param ! ut:filter-map(
                                map {
                                    "name": xs:string(@name),
                                    "type": xs:string(@type),
                                    "value": xs:string(@value)
                                },
                                ut:filter-entry-value-empty-sequence#2
                            )
                        }
                    },
                    ut:filter-entry-value-empty-sequence#2
                )
            },
            "text": array {
                $lucene/cc:text ! ut:filter-map(
                    map {
                        "qname": xs:string(@qname),
                        "match": xs:string(@match),
                        "analyzer": xs:string(@analyzer),
                        "ignore": array {
                            cc:ignore ! map {
                                "qname": xs:string(@qname)
                            }
                        },
                        "boost": xs:decimal(@boost),
                        "match-sibling-attr": array {
                            match-sibling-attr ! ut:filter-map(
                                map {
                                    "qname": xs:string(@qname),
                                    "value": xs:string(@value),
                                    "boost": xs:decimal(@boost)
                                },
                                ut:filter-entry-value-empty-sequence#2
                            )
                        },
                        "has-sibling-attr": array {
                            has-sibling-attr ! ut:filter-map(
                                map {
                                    "qname": xs:string(@qname),
                                    "value": xs:string(@value),
                                    "boost": xs:decimal(@boost)
                                },
                                ut:filter-entry-value-empty-sequence#2
                            )
                        },
                        "match-attr": array {
                            match-attr ! ut:filter-map(
                                map {
                                    "qname": xs:string(@qname),
                                    "value": xs:string(@value),
                                    "boost": xs:decimal(@boost)
                                },
                                ut:filter-entry-value-empty-sequence#2
                            )
                        },
                        "has-attr": array {
                            has-attr ! ut:filter-map(
                                map {
                                    "qname": xs:string(@qname),
                                    "value": xs:string(@value),
                                    "boost": xs:decimal(@boost)
                                },
                                ut:filter-entry-value-empty-sequence#2
                            )
                        }
                    },
                    ut:filter-entry-value-empty-sequence#2
                )
            },
            "ignore": array {
                $lucene/cc:ignore ! map {
                    "qname": xs:string(@qname)
                }
            }
        }
    else ()
};

declare
    %private
function idx:range-index($range as element(cc:range)?) as array(map(xs:string, item()))? {
    if ($range)
    then
        array {
            $range/cc:create ! ut:filter-map(
                map {
                    "qname": xs:string(@qname),
                    "type": xs:string(@type),
                    "case": if(@case eq "no")then false() else true(),
                    "collation": xs:string(@collation),
                    "conditions": array {
                        cc:condition ! ut:filter-map(
                            map {
                                "attribute": xs:string(@attribute),
                                "value": xs:string(@value)
                            },
                            ut:filter-entry-value-empty-sequence#2
                        )
                    },
                    "fields": array {
                        cc:field ! ut:filter-map(
                            map {
                                "name": xs:string(@name),
                                "match": xs:string(@match),
                                "type": xs:string(@type)
                            },
                            ut:filter-entry-value-empty-sequence#2
                        )
                    }
                },
                ut:filter-entry-value-empty-sequence#2
            )
        }
    else ()
};

declare
    %private
function idx:ngram-index($ngram as element(cc:ngram)*) as array(map(xs:string, item()))? {
    if ($ngram)
    then
        array {
            $ngram ! map {
                "qname": xs:string(@qname)
            }    
        }
    else()
};

declare
    %private
function idx:legacy-range-index($create as element(cc:create)*) as array(map(xs:string, item()))? {
    if ($create)
    then
        array {
            $create ! ut:filter-map(
                map {
                    "qname": xs:string(@qname),
                    "path": xs:string(@path),
                    "type": xs:string(@type)
                },
                ut:filter-entry-value-empty-sequence#2
            )
        }
    else ()
};

declare
    %private
function idx:get-configured-index($collection-uri as xs:string?) as element(cc:index)? {
    let $conf-uri := "/db/system/config" || $collection-uri || "/collection.xconf"
    return
        if (fn:doc-available($conf-uri))
        then
            (: Note: the predicate filters out index definitons which only mention the old legacy full-text index :)
            fn:doc($conf-uri)//cc:index[child::element()[local-name(.) ne "fulltext"]]
        else
            let $parent-collection-uri := ut:parent-path($collection-uri)
            return
                if ($parent-collection-uri)
                then
                    idx:get-configured-index($parent-collection-uri)
                else ()
            
};