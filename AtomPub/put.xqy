xquery version "1.0-ml";

import module namespace atompub="http://www.marklogic.com/modules/atompub"
       at "/AtomPub/atompub.xqy";

(:
import module namespace alert="http://marklogic.com/xdmp/alert"
       at "/MarkLogic/alert.xqy";
:)

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace mla="http://www.marklogic.com/ns/atompub";
declare namespace app="http://www.w3.org/2007/app";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace f="http://www.marklogic.com/ns/local-functions";

declare option xdmp:mapping "false";

declare variable $path as xs:string external;
declare variable $content-type as xs:string external;
declare variable $is-xml as xs:boolean external;
declare variable $body as document-node() external;

declare variable $CONFIG := doc("/etc/configuration.xml")/mla:configuration;
declare variable $binary-collection := "http://www.marklogic.com/collections/atompub/binary";
declare variable $entry-collection := "http://www.marklogic.com/collections/atompub/atom";

declare function f:put-entry() as element(mla:response) {
  let $alt-uri
    := if (ends-with($path, ".atom"))
       then
         substring($path, 1, string-length($path) - 5)
       else
         $path
  let $x := xdmp:log(concat("path: ", $path))
  let $y := xdmp:log(concat("altu: ", $alt-uri))
  let $alt-link
    := <link xmlns="http://www.w3.org/2005/Atom"
             rel="alternate"
             href="{concat($CONFIG/mla:root,$alt-uri)}"/>
  let $edit-link
    := <link xmlns="http://www.w3.org/2005/Atom"
             rel="edit"
             href="{concat($CONFIG/mla:edit-root,$path)}"/>
  let $svc-link
    := <link xmlns="http://www.w3.org/2005/Atom"
             rel="service"
	     type="application/atomsvc+xml"
             href="{concat($CONFIG/mla:edit-root,$CONFIG/mla:weblog-path,
                           xdmp:get-current-user(),'/service.xml')}"/>
  return
  <mla:response>
    <mla:code>200</mla:code>
    <mla:message>Ok</mla:message>
    <mla:body>{f:put($body/*, ($alt-link, $edit-link, $svc-link))}</mla:body>
  </mla:response>
};

declare function f:trim-ext($fn as xs:string) as xs:string {
  let $base := substring-before($fn, '.')
  let $ext := substring-after($fn, '.')
  return
    if (contains($ext,'.'))
    then
      concat($base,'.',f:trim-ext($ext))
    else
      $base
};

declare function f:put-media() {
  let $atomuri := concat(f:trim-ext($path), ".atom")
  let $atom := doc($atomuri)/*
  let $updated
    := if ($atom/app:edited)
       then
         (xdmp:log("Updated app:edited"),
         xdmp:node-replace($atom/app:edited,
	                   <app:edited>{atompub:now()}</app:edited>))
       else (xdmp:log(concat("Did not update app:edited",$atomuri))) (: FIXME: this can't happen, right? :)
  let $editor := concat("weblog-editor-",xdmp:get-current-user())
  let $curcoll := xdmp:document-get-collections($path)
  return
    (xdmp:log(concat("putting media: ", $path)),
     xdmp:document-insert($path,$body,
			  (xdmp:permission("weblog-reader", "read"),
			   xdmp:permission($editor, "update")),
			   $curcoll),
    <mla:response>
      <mla:code>200</mla:code>
      <mla:message>Ok</mla:message>
    </mla:response>)
};

declare function f:put($entry as element(atom:entry), $extra as element()*)
        as element(atom:entry)
{
  let $c-prop := xdmp:document-get-properties($path, xs:QName("atom:content"))
  let $l-prop := xdmp:document-get-properties($path, xs:QName("atom:link"))
  let $augentry :=
    <entry xmlns="http://www.w3.org/2005/Atom">
      { $entry/@* }
      { $entry/*[not(self::atom:id)
		 and not(self::atom:updated)
		 and not(self::app:edited)
		 and not(self::atom:content)
		 and not(self::atom:link)] }
      <id>{concat($CONFIG/mla:root, $path)}</id>
      <app:edited>{atompub:now()}</app:edited>
      <updated>{atompub:now()}</updated>
      { $entry/atom:link[@rel != 'edit'
                         and @rel != 'edit-media'
                         and @rel != 'alternate'
                         and @rel != 'self'] }
      { if ($c-prop) then $c-prop else $entry/atom:content }
      { if ($l-prop) then $l-prop else () }
      { $extra }
    </entry>
  return
    (xdmp:node-replace(doc($path)/*, $augentry),
(:
     alert:invoke-matching-actions("my-alert-config-uri", $augentry, <options/>),
:)
     $augentry)
};

if ($is-xml)
then
  f:put-entry()
else
  f:put-media()
