xquery version "1.0-ml"; 

import module namespace atompub="http://www.marklogic.com/modules/atompub"
       at "/AtomPub/atompub.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace mla="http://www.marklogic.com/ns/atompub";
declare namespace app="http://www.w3.org/2007/app";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace f="http://www.marklogic.com/ns/local-functions";
declare namespace prop="http://marklogic.com/xdmp/property";

declare option xdmp:mapping "false"; 

declare variable $error:errors as node()* external; 

declare variable $method  := xdmp:get-request-method();
declare variable $code    := xdmp:get-response-code()[1];
declare variable $message := xdmp:get-response-code()[2];
declare variable $path    := xdmp:get-request-path();
declare variable $error   := $error:errors;

declare function f:handle-get() {
  let $resp := atompub:get($path)
  return
    (xdmp:set-response-code(xs:int($resp/mla:code), $resp/mla:message),
     if ($resp/mla:content-type)
     then
       xdmp:set-response-content-type($resp/mla:content-type)
     else
       (),
     for $f in $resp/mla:header
     return
       xdmp:add-response-header($f/@name, $f/@value),
     if ($resp/mla:body)
     then
       $resp/mla:body/node()
     else
       doc($resp/mla:body-uri))
};

declare function f:handle-put() {
  let $resp := atompub:put($path)
  return
    (xdmp:set-response-code(xs:int($resp/mla:code), $resp/mla:message),
     if ($resp/mla:content-type)
     then
       xdmp:set-response-content-type($resp/mla:content-type)
     else
       (),
     for $f in $resp/mla:header
     return
       xdmp:add-response-header($f/@name, $f/@value),
     $resp/mla:body/node())
};

declare function f:handle-post() {
  if (atompub:is-collection-uri($path))
  then
    let $resp := atompub:post($path)
    return
      (xdmp:set-response-code(xs:int($resp/mla:code), $resp/mla:message),
       if ($resp/mla:content-type)
       then
         xdmp:set-response-content-type($resp/mla:content-type)
       else
         (),
       if ($resp/mla:uri)
       then
         (xdmp:add-response-header("Location", $resp/mla:uri),
	  xdmp:add-response-header("Content-Location", $resp/mla:uri))
       else
	 (),
       for $f in $resp/mla:header
       return
	 xdmp:add-response-header($f/@name, $f/@value),
       $resp/mla:body/node())
  else
    (xdmp:set-response-code(403, "Forbidden"),
     atompub:html-error(403, "Forbidden", ()))
};

declare function f:handle-delete() {
  let $resp := atompub:delete($path)
  return
    (xdmp:set-response-code(xs:int($resp/mla:code), $resp/mla:message),
     if ($resp/mla:content-type)
     then
       xdmp:set-response-content-type($resp/mla:content-type)
     else
       (),
     for $f in $resp/mla:header
     return
       xdmp:add-response-header($f/@name, $f/@value),
     $resp/mla:body/node())
};

let $debug := atompub:debug(concat("Error handler caught ", $code, " for ", $method))
return
if ($code = 404 or $code = 405)
then
  if ($method = "GET")
  then
    f:handle-get()
  else
    if ($method = "PUT")
    then
      f:handle-put()
    else
      if ($method = "POST")
      then
        f:handle-post()
      else
        if ($method = "DELETE")
        then
          f:handle-delete()
        else
	  (xdmp:set-response-code(405, "Not allowed"),
	   atompub:html-error(405, concat("Method not allowed: ", $method), ()))
else
  (xdmp:set-response-code($code, $message),
   atompub:html-error($code, $message, ()))
