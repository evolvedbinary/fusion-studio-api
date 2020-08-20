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
xquery version "1.0";

(:~
: Module which simply declares constants for the HTTP 1.1 Status Code Definitions
:
: @author Adam Retter <adam@evolvedbinary.com>
:)
module namespace hsc = "https://tools.ietf.org/html/rfc2616#section-10";

declare variable $hsc:continue := 100;
declare variable $hsc:switching-protocols := 101;

declare variable $hsc:ok := 200;
declare variable $hsc:created := 201;
declare variable $hsc:accepted := 202;
declare variable $hsc:non-authorative-information := 203;
declare variable $hsc:no-content := 204;
declare variable $hsc:reset-content := 204;
declare variable $hsc:partial-content := 206;

declare variable $hsc:multiple-choices := 300;
declare variable $hsc:moved-permanently := 301;
declare variable $hsc:found := 302;
declare variable $hsc:see-other := 303;
declare variable $hsc:not-modified := 304;
declare variable $hsc:use-proxy := 305;
declare variable $hsc:temporary-redirect := 307;

declare variable $hsc:bad-request := 400;
declare variable $hsc:unauthorized := 401;
declare variable $hsc:payment-required := 402;
declare variable $hsc:forbidden := 403;
declare variable $hsc:not-found := 404;
declare variable $hsc:method-not-allowed := 405;
declare variable $hsc:not-acceptable := 406;
declare variable $hsc:proxy-authentication-required := 407;
declare variable $hsc:request-timeout := 408;
declare variable $hsc:conflict := 409;
declare variable $hsc:gone := 410;
declare variable $hsc:length-required := 411;
declare variable $hsc:precondition-failed := 412;
declare variable $hsc:request-entity-too-large := 413;
declare variable $hsc:request-uri-too-long := 414;
declare variable $hsc:unsupported-media-type := 415;
declare variable $hsc:requested-range-not-satisfiable := 416;
declare variable $hsc:expectation-failed := 417;

declare variable $hsc:internal-server-error := 500;
declare variable $hsc:not-implemented := 501;
declare variable $hsc:bad-gateway := 502;
declare variable $hsc:service-unavailable := 503;
declare variable $hsc:gateway-timeout := 504;
declare variable $hsc:http-version-not-supported := 505;
