xquery version "1.0-ml";

import module namespace uit="http://www.marklogic.com/ps/lib/lib-uitools"
       at "/modules/lib-uitools.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace mla="http://www.marklogic.com/ns/atompub";
declare namespace app="http://www.w3.org/2007/app";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace prop="http://marklogic.com/xdmp/property";
declare namespace f="http://www.marklogic.com/ns/local-functions";

declare option xdmp:mapping "false"; 

declare variable $CONFIG := doc("/etc/configuration.xml")/mla:configuration;

declare function f:valid-username($username as xs:string) as xs:boolean {
  matches($username,"^[a-zA-Z][a-zA-Z0-9]+$")
};

declare function f:email($username as xs:string,
                         $email as xs:string,
			 $token as xs:unsignedLong)
        as empty-sequence()
{
  xdmp:email(
    <em:Message xmlns:em="URN:ietf:params:email-xml:" 
                xmlns:rf="URN:ietf:params:rfc822:">
      <rf:subject>AtomPub account created at microwave.homedns.org</rf:subject>
      <rf:from>
	<em:Address>
	  <em:name>AtomPub Server (Norman Walsh)</em:name>
	  <em:adrs>ndw@nwalsh.com</em:adrs>
	</em:Address>
      </rf:from>
      <rf:to>
	<em:Address>
	  <em:name>AtomPub User</em:name>
	  <em:adrs>{$email}</em:adrs>
	</em:Address>
      </rf:to>
      <em:content xml:space="preserve">
Hello,

You're receiving this message because you requested an account on Norm's
AtomPub test server. If you received this message in error, you can simply
ignore it.

To complete the creation of your account ({$username}), follow this link:
http://microwave.homedns.org:8600/create.xqy?token={$token}

Thanks for testing. Please let me know if you encounter any problems.
      </em:content>
    </em:Message>)
};

let $params := uit:load-params()
let $username := string($params/username)
let $password := string($params/password)
let $email := string($params/email)
let $title := string($params/title)
let $userdir := concat($CONFIG/mla:weblog-path,$username)
let $token := xdmp:hash64(concat($username,string(current-dateTime())))
return
  if (not(f:valid-username($username)) or ($password = "")
      or ($email = "") or not(contains($email,"@")) or ($title = ""))
  then
    <error>Bad parameters.</error>
  else
    if ($CONFIG/mla:user[@href = $userdir]
        or $CONFIG/mla:putative-user[@href = $userdir])
    then
      <error>Username already exists.</error>
    else
      (xdmp:node-insert-child($CONFIG,
         <mla:putative-user href="{$userdir}">
	  <mla:username>{$username}</mla:username>
	  <mla:password>{$password}</mla:password>
	  <mla:email>{$email}</mla:email>
	  <mla:title>{$title}</mla:title>
	  <mla:token>{$token}</mla:token>
	</mla:putative-user>),
	f:email($username, $email, $token),
	<success>
	  <username>{$username}</username>
	  <email>{$email}</email>
	</success>)
