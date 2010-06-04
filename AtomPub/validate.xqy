xquery version "1.0-ml"; 

import module namespace atompub="http://www.marklogic.com/modules/atompub"
       at "/AtomPub/atompub.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace mla="http://www.marklogic.com/ns/atompub";
declare namespace app="http://www.w3.org/2007/app";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace f="http://www.marklogic.com/ns/local-functions";

declare option xdmp:mapping "false"; 

declare variable $path as xs:string external; 
declare variable $content-type as xs:string? external; 
declare variable $is-xml as xs:boolean external; 
declare variable $body as document-node() external;

declare variable $CONFIG := doc("/etc/configuration.xml")/mla:configuration;

declare function f:valid-xml() as xs:boolean {
  let $isentry := not(empty($body/atom:entry))
  let $vcategory := atompub:valid-categories($path, $body/*/atom:category)
  return
     $isentry and $vcategory
};

declare function f:valid-binary() as xs:boolean {
  true()
};

(: If we don't get a content type, just assume it's ok? :)
let $vct := if ($content-type = "application/octet-stream")
            then
	      true()
	    else
	      atompub:valid-content-type($path, $content-type)
let $dvct := atompub:debug(concat("Valid content type: (", $path, ",",$content-type,"): ", $vct))
let $vbd
  := if ($is-xml)
     then
       f:valid-xml()
     else
       f:valid-binary()
let $dvbd := atompub:debug(concat("Valid body: ", $vbd))
return
  $vct and $vbd
