xquery version "1.0-ml"; 

import module namespace aadm="http://www.marklogic.com/modules/atompub/admin"
       at "/AtomPub/admin.xqy";

import module namespace uit="http://www.marklogic.com/ps/lib/lib-uitools"
       at "/AtomPub/lib-uitools.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace mla="http://www.marklogic.com/ns/atompub";
declare namespace app="http://www.w3.org/2007/app";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace f="http://www.marklogic.com/ns/local-functions";

declare option xdmp:mapping "false"; 

declare variable $DEBUG as xs:boolean := false();
declare variable $CONFIG := doc("/etc/configuration.xml")/mla:configuration;

let $params := uit:load-params()
let $token := string($params/token)
let $puser := $CONFIG/mla:putative-user[mla:token = $token]
return
  if ($puser) 
  then
    try {
      let $doc := aadm:create-user($puser/mla:username,$puser/mla:password, $token)
      let $uri := concat($CONFIG/mla:edit-root,$CONFIG/mla:weblog-path,
                         $puser/mla:username,"/service.xml")
      return
        <html xmlns="http://www.w3.org/1999/xhtml">
	  <head>
	    <title>User {string($puser/mla:username)} created</title>
	  </head>
	  <body>
	    <h1>Welcome {string($puser/mla:username)}</h1>
	    <p>You can now point your AtomPub client at your service document:
	    <a href="{$uri}">{$uri}</a>.
	    </p>
	  </body>
        </html>
    } catch ($e) {
        <html xmlns="http://www.w3.org/1999/xhtml">
	  <head>
	    <title>User {string($puser/mla:username)} not created</title>
	  </head>
	  <body>
	    <h1>Sorry {string($puser/mla:username)}</h1>
	    <p>Your user name could not be created:
            { string($e/error:format-string/text()) }
            </p>
            <p>Please try a different name.
            </p>
	  </body>
        </html>

    }
  else
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
	<title>Something went wrong</title>
      </head>
      <body>
	  <title>Something went wrong</title>
	  <p>I guess you better tell Norm.</p>
	</body>
      </html>
