xquery version "3.1";

module namespace config = "http://fusiondb.com/ns/studio/api/config";

declare variable $config:version as xs:string := "${project.version}";
