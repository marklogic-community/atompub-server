xquery version "1.0-ml";

module namespace aadm="http://www.marklogic.com/modules/atompub/admin";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace mla="http://www.marklogic.com/ns/atompub";
declare namespace app="http://www.w3.org/2007/app";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace mt="http://marklogic.com/xdmp/mimetypes";

declare option xdmp:mapping "false"; 

declare variable $DEBUG := false();
declare variable $DOEMAIL := false();
declare variable $CONFIG := doc("/etc/configuration.xml")/mla:configuration;

declare function aadm:email($username as xs:string,
                         $email as xs:string,
			 $token as xs:unsignedLong)
        as empty-sequence()
{
  if ($DOEMAIL)
  then
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
	<em:content xml:space="preserve">Hello,

You're receiving this message because you requested an account on [NAME
OF SERVICE] test server. If you received this message in error, you can simply
ignore it.

To complete the creation of your account ({$username}), follow this link:
[LINK TO CREATE USER]

Thanks for testing. Please let me know if you encounter any problems.

[YOUR HOSTS]</em:content>
    </em:Message>)
  else
    xdmp:log(concat("Would have emailed this token: ", $token))
};

declare function aadm:create-putative-user($username as xs:string,
		                        $password as xs:string,
		                        $email as xs:string,
		                        $title as xs:string,
		                        $token as xs:unsignedLong) 
{
  (xdmp:node-insert-child($CONFIG,
     <mla:putative-user userid="{$username}">
       <mla:username>{$username}</mla:username>
       <mla:password>{$password}</mla:password>
       <mla:email>{$email}</mla:email>
       <mla:title>{$title}</mla:title>
       <mla:token>{$token}</mla:token>
       </mla:putative-user>),
   aadm:email($username, $email, $token),
   <success>
     <username>{$username}</username>
     <email>{$email}</email>
     { if ($DOEMAIL) 
       then
         ()
       else
         <token>{$token}</token>
     }
   </success>)
};

declare function aadm:sec($func as xs:string, $params as xs:string) {
  if ($DEBUG)
  then aadm:show-sec($func,$params)
  else aadm:do-sec($func,$params)
};

declare function aadm:show-sec($func as xs:string, $params as xs:string) {
  let $funcall := concat("sec:", $func, "(", $params, ")")
  return
    $funcall
};

declare function aadm:do-sec($func as xs:string, $params as xs:string) {
  let $secmod := "import module namespace sec='http://marklogic.com/xdmp/security' at '/MarkLogic/security.xqy'; "
  let $funcall := concat("sec:", $func, "(", $params, ")")
  return
    xdmp:eval(concat($secmod,$funcall), (),
      <options xmlns="xdmp:eval">
        <database>{xdmp:security-database()}</database>
      </options>)
};

declare function aadm:create-user($user-name as xs:string,
                                  $user-password as xs:string,
		                  $token as xs:string)
        as element()
{
  let $user-uri-priv := concat("weblog-edit-", $user-name)
  let $user-uri := concat($CONFIG/mla:weblog-path, $user-name, "/")
  let $uri-priv := aadm:sec("create-privilege",
                       concat("'",$user-uri-priv, "','", $user-uri, "','uri'",
		              ",()"))

  let $user-role-name := concat("weblog-editor-", $user-name)
  let $user-role-desc := concat("Editor of ", $user-name, "''s weblog")
  let $user-role := aadm:sec("create-role",
                        concat("'",$user-role-name, "','", $user-role-desc, "',",
                               "('weblog-editor'), (), ()"))

  let $user-desc := concat("Weblog user ", $user-name)
  let $user := aadm:sec("create-user",
                   concat("'", $user-name, "','", $user-desc, "','", $user-password,
                          "',('",$user-role-name,"'), (), ()"))

  let $privrole := aadm:sec("privilege-add-roles",
                         concat("'",$user-uri,"','uri','",$user-role-name,"'"))

   let $puser := $CONFIG/mla:putative-user[mla:token = $token]
   let $user
     := <mla:user userid="{$puser/@userid}">
          { $puser/mla:email }
	  { $puser/mla:title }
	</mla:user>
   let $patch := xdmp:node-replace($puser,$user)
return
  <doc>
    <uri>{$uri-priv}</uri>
    <role>{$user-role}</role>
    <user>{$user}</user>
  </doc>
};
