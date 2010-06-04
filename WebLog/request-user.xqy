xquery version "1.0-ml";

import module namespace aadm="http://www.marklogic.com/modules/atompub/admin"
       at "/AtomPub/admin.xqy";

import module namespace uit="http://www.marklogic.com/ps/lib/lib-uitools"
       at "/AtomPub/lib-uitools.xqy";

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

let $params := uit:load-params()
let $username := string($params/username)
let $password := string($params/password)
let $email := string($params/email)
let $title := string($params/title)
let $token := xdmp:hash64(concat($username,string(current-dateTime())))
return
  if (not(f:valid-username($username)) or ($password = "")
      or ($email = "") or not(contains($email,"@")) or ($title = ""))
  then
    <error>
      <message>bad parameters; empty field or malformed email address?</message>
      <username>{$username}</username>
      <password>{$password}</password>
      <email>{$email}</email>
      <title>{$title}</title>
      <token>{$token}</token>
    </error>
  else
    if ($CONFIG/mla:user[@userid = $username]
        or $CONFIG/mla:putative-user[@userid = $username]
        or $CONFIG/mla:reserved[@userid = $username])
    then
      <error>
        <message>username "{$username}" already exists or is not allowed.</message>
      </error>
    else
      aadm:create-putative-user($username, $password, $email, $title, $token)
