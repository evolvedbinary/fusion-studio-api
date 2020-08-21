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

module namespace perr = "http://fusiondb.com/ns/studio/api/error";

declare variable $perr:PD001 := map {
    "code": fn:QName("http://fusiondb.com/ns/studio/api/error", "PD001"),
    "description": "Permission Denied"
};

declare variable $perr:PD002 := map {
    "code": fn:QName("http://fusiondb.com/ns/studio/api/error", "PD002"),
    "description": "Source Collection URI, does not exist"
};

declare variable $perr:PD003 := map {
    "code": fn:QName("http://fusiondb.com/ns/studio/api/error", "PD003"),
    "description": "Source Document URI, does not exist"
};

declare variable $perr:AP001 := map {
    "code": fn:QName("http://fusiondb.com/ns/studio/api/error", "AP001"),
    "description": "Missing request body"
};

declare variable $perr:XQ001 := map {
    "code": fn:QName("http://fusiondb.com/ns/studio/api/error", "XQ001"),
    "description": "Stored query does not exist"
};

declare variable $perr:XQ002 := map {
    "code": fn:QName("http://fusiondb.com/ns/studio/api/error", "XQ002"),
    "description": "An error occurred whilst evaluating the query"
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