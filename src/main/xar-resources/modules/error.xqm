xquery version "3.1";

module namespace perr = "http://evolvedbinary.com/ns/pebble/api/error";

declare variable $perr:PD001 := map {
    "code": fn:QName("http://evolvedbinary.com/ns/pebble/api/error", "PD001"),
    "description": "Permission Denied"
};

declare variable $perr:PD002 := map {
    "code": fn:QName("http://evolvedbinary.com/ns/pebble/api/error", "PD002"),
    "description": "Source Collection URI, does not exist"
};

declare variable $perr:PD003 := map {
    "code": fn:QName("http://evolvedbinary.com/ns/pebble/api/error", "PD003"),
    "description": "Source Document URI, does not exist"
};

declare function perr:error($error as map(xs:string, item())) {
    perr:error($error, (), ())
};

declare function perr:error($error as map(xs:string, item()), $message as xs:string) {
    perr:error($error, $message, ())
};

declare function perr:error($error as map(xs:string, item()), $message as xs:string?, $error-object as item()*) {
    let $msg :=
        if ($message)
        then
            $error?description || ": " || $message
        else
            $error?description
    return
        fn:error($error?code, $msg, $error-object)
};