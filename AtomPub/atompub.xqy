xquery version "1.0-ml";

module namespace atompub="http://www.marklogic.com/modules/atompub";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace mla="http://www.marklogic.com/ns/atompub";
declare namespace app="http://www.w3.org/2007/app";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace mt="http://marklogic.com/xdmp/mimetypes";

declare option xdmp:mapping "false"; 

declare variable $DEBUG := true();
declare variable $CONFIG := doc("/etc/configuration.xml")/mla:configuration;
declare variable $binary-collection := "http://www.marklogic.com/collections/atompub/binary";
declare variable $entry-collection := "http://www.marklogic.com/collections/atompub/atom";
declare variable $mimetypes := xdmp:read-cluster-config-file("mimetypes.xml");

declare variable $default-modules
  := <mla:default-modules>
       <mla:module method="post">/AtomPub/post.xqy</mla:module>
       <mla:module method="put">/AtomPub/put.xqy</mla:module>
       <mla:module method="format">/AtomPub/format.xqy</mla:module>
       <mla:module method="validate">/AtomPub/validate.xqy</mla:module>
     </mla:default-modules>;

declare function atompub:mime-type-extension($mimetype as xs:string) as xs:string? {
  let $ext := $mimetypes/mt:mimetypes/mt:mimetype[mt:name eq $mimetype]/mt:extensions
  return
    if ($ext)
    then
      if (contains(string($ext)," "))
      then
        substring-before(string($ext), " ")
      else
	string($ext)
    else
      "media"
};

declare function atompub:service-document-uri() as xs:string {
  let $userid := xdmp:get-current-user()
  return
    atompub:service-document-uri($userid)
};

declare function atompub:service-document-uri($userid as xs:string) as xs:string {
  if ($CONFIG/mla:user[@userid = $userid]/mla:service)
  then
    string($CONFIG/mla:user[@userid = $userid]/mla:service/@href)
  else
    concat($CONFIG/mla:weblog-path, $userid, "/service.xml")
};

declare function atompub:service-document() as element(app:service)? {
  let $userid := xdmp:get-current-user()
  return
    atompub:service-document($userid)
};
  
declare function atompub:service-document($userid as xs:string) as element(app:service)? {
  let $service-uri := atompub:service-document-uri($userid)
  return
    if (doc-available($service-uri))
    then
      doc($service-uri)/app:service
    else
      <service xmlns="http://www.w3.org/2007/app"
               xmlns:mla="http://www.marklogic.com/ns/atompub"
               xmlns:atom="http://www.w3.org/2005/Atom">
       <workspace>
	 <atom:title>{$userid}'s Weblog</atom:title>
	 <collection href="{concat($CONFIG/mla:edit-root,$CONFIG/mla:weblog-path,$userid, '/main')}">
	   <atom:title>Weblog Entries</atom:title>
	   <atom:author><atom:name>{$userid}</atom:name></atom:author>
	   <categories scheme="http://www.marklogic.com/atompub/categories/"
	               fixed="no">
	     <atom:category term="animal" />
	     <atom:category term="vegatable" />
	     <atom:category term="mineral" />
	   </categories>
	   <accept>text/xml</accept>
	   <accept>application/xml</accept>
	   <accept>application/atom+xml</accept>
	   <accept>application/atom+xml;type=entry</accept>
	 </collection>
	 <collection href="{concat($CONFIG/mla:edit-root,$CONFIG/mla:weblog-path,$userid, '/pictures')}">
	   <atom:title>Weblog Pictures</atom:title>
	   <atom:author><atom:name>{$userid}</atom:name></atom:author>
	   <categories scheme="http://www.marklogic.com/atompub/categories/"
	               fixed="no">
	     <atom:category term="animal" />
	     <atom:category term="vegatable" />
	     <atom:category term="mineral" />
	   </categories>
	   <accept>application/xml</accept>
	   <accept>application/atom+xml</accept>
	   <accept>application/atom+xml;type=entry</accept>
	   <accept>image/png</accept>
	   <accept>image/jpeg</accept>
	   <accept>image/gif</accept>
	 </collection>
       </workspace>
      </service>
};

declare function atompub:is-collection-uri($uri as xs:string) as xs:boolean {
  let $service := atompub:service-document()
  let $curi := concat($CONFIG/mla:edit-root,$uri)
  let $collection := $service//app:collection[@href = $curi]
  return 
    not(empty($collection))
};

declare function atompub:get-member-resources($collection as xs:string)
        as document-node(atom:feed)
{
  let $feedmeta := $CONFIG/mla:collection[@href = $collection]/atom:*
  (: I'm not sure about this... :)
  let $post := substring-after($collection, $CONFIG/mla:weblog-path)
  let $userid := substring-before($post, "/")
  let $title := $CONFIG/mla:user[@userid=$userid]/mla:title
  return
  document {
    <feed xmlns="http://www.w3.org/2005/Atom">
      { if (not($feedmeta[self::atom:title]))
        then
          <title xmlns="http://www.w3.org/2005/Atom">{string($title)}</title>
        else
	  ()
      }
      { $feedmeta }
      <id>{concat($CONFIG/mla:edit-root, $collection)}</id>
      <link rel='self' href="{concat($CONFIG/mla:root, $collection)}"/>
      <link rel="service" type="application/atomsvc+xml"
            href="{concat($CONFIG/mla:edit-root,$CONFIG/mla:weblog-path,
                          $userid,'/service.xml')}"/>
      <updated>{atompub:now()}</updated>
      <generator>{string($CONFIG/mla:generator)}</generator>
        { for $entry in collection(concat($entry-collection,$collection))
  	  order by $entry/app:edited descending
	  return
	    $entry
	}
    </feed>
  }
};

declare function atompub:now() as xs:dateTime {
  (: current dateTime in UTC w/o fractional seconds :)
  let $tz :=  xs:dayTimeDuration("PT0H")
  let $timestr := string(adjust-dateTime-to-timezone(current-dateTime(), $tz))
  let $nowstr := if (contains($timestr,"."))
                 then concat(substring-before($timestr,"."),"Z")
		 else $timestr
  return
    xs:dateTime($timestr)
};

declare function atompub:_zpad($number as xs:int) as xs:string {
  if ($number < 10)
  then
    concat("0", string($number))
  else
    string($number)
};

declare function atompub:ymd-uri-fragment() {
  let $dt := current-dateTime()
  let $year := year-from-dateTime($dt)
  let $month := atompub:_zpad(month-from-dateTime($dt))
  let $day := atompub:_zpad(day-from-dateTime($dt))
  return
    concat($year,"/",$month,"/",$day)
};

declare function atompub:hms-uri-fragment() {
  let $dt := current-dateTime()
  let $hour := atompub:_zpad(hours-from-dateTime($dt))
  let $min := atompub:_zpad(minutes-from-dateTime($dt))
  let $sec := atompub:_zpad(floor(seconds-from-dateTime($dt)))
  return
    concat($hour,".",$min,".",$sec)
};

declare function atompub:new-uri($baseuri as xs:string, $rawslug as xs:string?)
        as xs:anyURI
{
  let $sbase := if (ends-with($baseuri, ".atom"))
                then substring($baseuri, 1, string-length($baseuri) - 5)
	        else $baseuri
  let $base := if (ends-with($sbase,"/")) then $sbase else concat($sbase,"/")
  let $slug := if (empty($rawslug)) then () else encode-for-uri($rawslug)
  let $ymd := atompub:ymd-uri-fragment()
  let $hms := atompub:hms-uri-fragment()
  let $ymduri := concat($base, $ymd, "/")
  let $uri
    := if (not(empty($slug)) and not(doc-available(concat($ymduri, $slug))))
         (: this doc-available check isn't really safe, but ... :)
       then
         xs:anyURI(concat($ymduri, $slug))
       else
         xs:anyURI(concat($ymduri, $hms, "-", xdmp:random()))
  let $log := atompub:debug(concat("New uri: ", $uri))
  return
    $uri
};

declare function atompub:get($uri as xs:string) as element(mla:response) {
  (: There are two possibilities. If the current user is 'joepublic' then
     we want to send back formatted versions of URIs by default. If the
     current user is anyone else, we want to send back editable feeds. :)
  if (xdmp:get-current-user() = string($CONFIG/mla:weblog-reader))
  then
    (atompub:debug(concat("Getting for reader: ", $uri)),
     atompub:_get-for-reader($uri))
  else
    (atompub:debug(concat("Getting for editor: ", $uri)),
     atompub:_get-for-editor($uri))
};

declare function atompub:_get-for-reader($uri as xs:string)
        as element(mla:response)
{
  (: What might we be trying to get?

     1. Some URI (an entry, a media file), that is in the database.
        e.g., /u/<username>/<path>/entry.atom
     2. The root of the users's weblog, in which case we want to return
        the HTML formatted version of their main weblog. e.g., /u/<username>/
     3. The ID of some entry w/o the .atom suffix, in which case we want
        to return the formatted version of that entry
     4. The name of one of the user's collections in which case we want to
        return the HTML formatted version of that feed
        /u/<username>/pictures
  :)

  if (doc-available($uri))
  then
    atompub:_get-document($uri)
  else
    if (false() and atompub:weblog-root($uri)) 
    then
      atompub:_get-formatted-entry(concat($uri,"/main"),
                    atompub:get-member-resources(concat($uri,"/main"))/*)
    else
      if (atompub:weblog-collection($uri))
      then
        atompub:_get-formatted-entry($uri,
                      atompub:get-member-resources($uri)/*)
      else
        if (doc-available(concat($uri,".atom")))
        then
          atompub:_get-formatted-entry(concat($uri, ".atom"),
                      doc(concat($uri, ".atom"))/*)
        else
          if (atompub:is-collection-uri($uri))
          then
            atompub:_get-formatted-entry($uri, 
                      atompub:get-member-resources($uri)/*)
          else
            <mla:response>
              {atompub:debug(concat("get 404: ", $uri))}
              {atompub:debug(concat("for user: ", xdmp:get-current-user()))}
              <mla:code>404</mla:code>
              <mla:message>Not Found</mla:message>
              <mla:body>{atompub:html-error(404,"Not Found",())}</mla:body>
            </mla:response>
};

declare function atompub:_get-for-editor($uri as xs:string)
        as element(mla:response)
{
  (: What might we be trying to get?

     1. The current users's service document
        e.g., /u/<username>/service.xml
     2. Some URI (an entry, a media file), that is in the database.
        e.g., /u/<username>/<path>/entry.atom
     3. The name of one of the user's collections in which case we want to
        return the feed for that collection, e.g., /u/<username>/pictures
  :)
  if ($uri = atompub:service-document-uri())
  then
    <mla:response>
      {atompub:debug(concat("get service: ", $uri))}
      <mla:code>200</mla:code>
      <mla:message>Ok</mla:message>
      <mla:content-type>application/atomsvc+xml</mla:content-type>
      <mla:body>{atompub:service-document()}</mla:body>
    </mla:response>
  else
    if (doc-available($uri))
    then
      atompub:_get-document($uri)
    else
      if (atompub:is-collection-uri($uri))
      then
        <mla:response>
          {atompub:debug(concat("get collection: ", $uri))}
  	  <mla:code>200</mla:code>
	  <mla:message>ok</mla:message>
	  <mla:content-type>application/atom+xml</mla:content-type>
	  <mla:body>{atompub:get-member-resources($uri)}</mla:body>
	</mla:response>
      else
        <mla:response>
          {atompub:debug(concat("get 404: ", $uri))}
	  {atompub:debug(concat("for user: ", xdmp:get-current-user()))}
  	  <mla:code>404</mla:code>
	  <mla:message>not found</mla:message>
	  <mla:body>{atompub:html-error(404,"not found",())}</mla:body>
	</mla:response>
};

declare function atompub:_get-document($uri as xs:string)
        as element(mla:response)
{
  let $lm := xdmp:document-properties($uri)/prop:properties/prop:last-modified
  let $ct := xdmp:document-properties($uri)/prop:properties/mla:content-type
  return
    <mla:response>
      {atompub:debug(concat("get available: ", $uri))}
      <mla:code>200</mla:code>
      <mla:message>Ok</mla:message>
      { if ($lm)
        then
  	  <mla:header name="Last-Modified" value="{$lm}"/>
  	else
  	  ()
      }
      { if ($ct)
        then
	  (atompub:debug(concat("Returning binary content: ", $ct)),
	   $ct,
	   <mla:body-uri>{$uri}</mla:body-uri>)
        else
          (atompub:debug(concat("Returning XML content: ", $ct)),
	   <mla:content-type>application/atom+xml</mla:content-type>,
           (: I wonder if this is worth it. I'm betting not... :)
  	   <mla:header name="ETag"
	               value="{string(xdmp:hash64(xdmp:quote(doc($uri))))}"/>,
	   <mla:body>{doc($uri)}</mla:body>)
      }
    </mla:response>
};

declare function atompub:_get-formatted-entry($uri as xs:string, $entry as element())
        as element(mla:response)
{
  let $module := atompub:_module($uri, "format")
  return
    xdmp:invoke($module, (xs:QName("doc"), $entry))
};

declare function atompub:post($uri as xs:string) as element(mla:response) {
  atompub:_post-or-put($uri, "post")
};

declare function atompub:put($uri as xs:string) as element(mla:response) {
  atompub:_post-or-put($uri, "put")
};

declare function atompub:_post-or-put($uri as xs:string, $verb as xs:string)
        as element(mla:response) {
  let $validmod := atompub:_module($uri, "validate")
  let $postmod := atompub:_module($uri, $verb)
  let $content-type := xdmp:get-request-header("Content-type")
  let $isxml := atompub:xml-media-type($content-type)
  let $body := if ($isxml)
               then
  	         xdmp:get-request-body("xml")
	       else
	         xdmp:get-request-body()
  let $external := (xs:QName("path"), $uri,
                    if (not(empty($content-type)))
		    then
                      (xs:QName("content-type"), $content-type)
		    else
                      (xs:QName("content-type"), "application/octet-stream"),
		    xs:QName("is-xml"), $isxml,
		    xs:QName("body"), $body)
  return
    if (xdmp:invoke($validmod, $external))
    then
      xdmp:invoke($postmod, $external)
    else
      <mla:response>
	<mla:code>403</mla:code>
	<mla:message>Invalid entry</mla:message>
	{ if ($isxml)
          then
	    <mla:body>{$body/*}</mla:body>
	  else
	    ()
	}
      </mla:response>
};

declare function atompub:delete($uri as xs:string) as element(mla:response) {
  let $c-prop := xdmp:document-get-properties($uri, xs:QName("atom:content"))
  let $curi := substring-after($c-prop/@src,$CONFIG/mla:root)
  return
    if (doc-available($uri))
    then
      (if ($c-prop) then xdmp:document-delete($curi) else (),
      xdmp:document-delete($uri),
       <mla:response>
	 <mla:code>200</mla:code>
	 <mla:message>Ok</mla:message>
       </mla:response>)
    else
      <mla:response>
        <mla:code>404</mla:code>
        <mla:message>Not Found</mla:message>
        <mla:body>{atompub:html-error(404,"Not Found",())}</mla:body>
      </mla:response>
};

declare function atompub:weblog-root($uri as xs:string) as xs:boolean {
  let $bareuri
    := if (ends-with($uri,"/"))
       then substring($uri, 1, string-length($uri)-1)
       else $uri
  let $userid := substring-after($bareuri, $CONFIG/mla:weblog-path)
  return
    starts-with($uri, $CONFIG/mla:weblog-path)
    and not(empty($CONFIG/mla:user[@userid = $userid]))
};

declare function atompub:weblog-collection($uri as xs:string) as xs:boolean {
  let $bareuri
    := if (ends-with($uri,"/"))
       then substring($uri, 1, string-length($uri)-1)
       else $uri
  let $post := substring-after($bareuri, $CONFIG/mla:weblog-path)
  let $userid := substring-before($post, "/")
  let $cname := substring-after($post, "/")
  let $collection := concat($CONFIG/mla:edit-root,$CONFIG/mla:weblog-path,
                            $userid,'/',$cname)
  let $svc := atompub:service-document($userid)
  return
    starts-with($uri, $CONFIG/mla:weblog-path)
    and not(empty($CONFIG/mla:user[@userid = $userid]))
    and not(empty($svc/app:workspace/app:collection[@href=$collection]))
};

declare function atompub:valid-categories($collection as xs:string,
                                          $category as element(atom:category)*)
        as xs:boolean
{
  let $service := atompub:service-document()
  let $curi := concat($CONFIG/mla:edit-root,$collection)
  let $appcoll := $service/app:workspace/app:collection[@href = $curi]
  let $categories := $appcoll/app:categories
  let $fixed := $categories/@fixed = "yes"
  let $chkcat
    := for $acat in $category    
       let $chklist
	 := for $cat in $categories/atom:category
	    let $scheme 
	      := if ($cat/@scheme) then $cat/@scheme else $categories/@scheme
            let $ok := ($acat/@scheme = $scheme and $acat/@term = $cat/@term)
	    return
	      $ok
       return
	 $chklist = true()
  return
     not($category) or not($fixed) or $chkcat = true()
};

declare function atompub:valid-content-type($uri as xs:string,
                                            $content-type as xs:string)
        as xs:boolean
{
  let $collection := atompub:find-collection-for-uri($uri)
  let $service := atompub:service-document()
  let $curi := concat($CONFIG/mla:edit-root,$collection)
  let $appcoll := $service/app:workspace/app:collection[@href = $curi]
  let $accept := $appcoll/app:accept
  return
    $accept = $content-type
};

declare function atompub:find-collection-for-uri($uri as xs:string) as xs:string {
  (: Note: Entries can appear in more than one collection. Workspaces
     can have more than one collection. This code just finds the first
     match; so if all the collections aren't consistent... :)
  if (doc-available($uri)) 
  then
    let $coll := xdmp:document-get-collections($uri)[1]
    let $suffix := substring-after($coll, "http://www.marklogic.com/collections/atompub/")
    return
      concat("/", substring-after($suffix,"/"))
  else
    $uri
};

declare function atompub:xml-media-type($content-type as xs:string?) as xs:boolean {
  if (empty($content-type))
  then
    false()
  else
    starts-with($content-type, "application/xml")
    or starts-with($content-type, "text/xml")
    or ends-with($content-type, "+xml")
    or contains($content-type, "+xml;")
};

declare function atompub:html-error($code as xs:int, $message as xs:string,
			            $error as xs:string?) {
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>{$code}&#160;{$message}</title>
      <meta name="robots" content="noindex,nofollow"/>
    </head>
    <body>
      <h1>{$code}&#160;{$message}</h1>
      { if ($error)
        then
          <pre>{$error}</pre>
	else
	  ()
      }
    </body>
  </html>
};

declare function atompub:debug($msg as xs:string) as empty-sequence() {
  if ($DEBUG) 
  then
    xdmp:log($msg)
  else
    ()
};

declare function atompub:_module($uri as xs:string, $method as xs:string)
        as xs:string?
{
  let $module := ($CONFIG/mla:collection[@href = $uri]/mla:module[@method=$method],
                  $CONFIG/mla:module[@method=$method],
		  $default-modules/mla:module[@method=$method])[1]
  return
    if ($module) then string($module) else ()
};

