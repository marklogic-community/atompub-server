xquery version "1.0-ml"; 

import module namespace atompub="http://www.marklogic.com/modules/atompub"
       at "/AtomPub/atompub.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace mla="http://www.marklogic.com/ns/atompub";
declare namespace app="http://www.w3.org/2007/app";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace f="http://www.marklogic.com/ns/local-functions";

declare option xdmp:mapping "false"; 

declare variable $doc as element() external;

declare variable $CONFIG := doc("/etc/configuration.xml")/mla:configuration;

declare function f:format($entry as element()) {
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>{string($entry/atom:title)}</title>
    </head>
    <body>
      <h1>{string($entry/atom:title)}</h1>
      {	if ($entry/self::atom:entry)
        then
  	  f:format-entry($entry)
	else
	  f:format-feed($entry)
      }
    </body>
  </html>
};

declare function f:format-entry($entry as element(atom:entry)) {
  let $x := xdmp:log("format entry")
  return
  f:format-content($entry/atom:content)
};

declare function f:format-feed($feed as element(atom:feed)) {
  let $x := xdmp:log("format feed")
  return
  for $entry in $feed/atom:entry
  return
    <div xmlns="http://www.w3.org/1999/xhtml">
      <h1>{string($entry/atom:title)}</h1>
      {f:format-content($entry/atom:content)}
    </div>
};

declare function f:format-content($content as element(atom:content)) {
  if ($content/@type = "text" or not($content/@type)) 
  then
    <p xmlns="http://www.w3.org/1999/xhtml">
      {string($content)}
    </p>
  else
    if ($content/@type = "html")
    then
      xdmp:tidy(string($content))[2]/*/*[2]/node()
    else
      if ($content/@src)
      then
        <img xmlns="http://www.w3.org/1999/xhtml"
	     src="{$content/@src}"/>
      else
	$content/node()
};

<mla:response>
  <mla:code>200</mla:code>
  <mla:message>Ok</mla:message>
  <mla:content-type>text/html</mla:content-type>
  <mla:body>{f:format($doc)}</mla:body>
</mla:response>
