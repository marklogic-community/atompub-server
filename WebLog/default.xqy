xquery version "1.0-ml"; 

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace mla="http://www.marklogic.com/ns/atompub";
declare namespace app="http://www.w3.org/2007/app";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace f="http://www.marklogic.com/ns/local-functions";
declare namespace prop="http://marklogic.com/xdmp/property";

declare option xdmp:mapping "false"; 

declare variable $CONFIG := doc("/etc/configuration.xml")/mla:configuration;

<html>
  <head>
    <title>Experimental AtomPub Server</title>
    <script type="text/javascript" src="http://www.google.com/jsapi"></script>
    <script type="text/javascript">
      google.load("jquery", "1.4");
      google.setOnLoadCallback(function() {{
        // Place init code here instead of $(document).ready()
      }});
    </script>
    <script src="js/atompub.js" type="text/javascript"></script>
    <link rel="stylesheet" href="/css/demo.css" type="text/css"/>
    <link rel="stylesheet" href="css/atompub.css" type="text/css"/>
  </head>
  <body>
    <h1>Experimental AtomPub Server</h1>
{(:
    <p>This is <a href="mailto:ndw@nwalsh.com">Norm</a>'s experimental
    AtomPub server. If you want to poke it with your favorite AtomPub
    client, drop me a line and I'll create an account for you.</p>
    <p>Be aware that <em>everything</em> you post on this server is 
    <a href="{$CONFIG/mla:root}/">made public</a>. I
    make no guarantees about service: it's just for testing. The
    server will go up and down periodically. Everything you post may
    be deleted without warning; in fact, you can be sure it will be
    eventually.</p>
    <p>But that needn't stop you from playing with it.</p>
:)}

    <h2>Create account</h2>
    <div id="create">
      <form method="get" action="/request-user.xqy"
            onsubmit="return checkAcct();">
	<p>
	  <span id="s-username">User name:
	  <input type="text" id="username" size="10"/></span>
	  &#160;
	  <span id="s-password">Password:
	  <input type="text" id="password" size="10"/></span>
	</p>
	<p>
	  <span id="s-email">Email address:
	  <input type="text" id="email" size="30"/>
	  (required)</span>
	</p>
	<p>
	  <span id="s-title">Weblog title:
	  <input type="text" id="title" size="40"/></span>
	  &#160; <input type="submit" value="Create"/>
	</p>
      </form>
      <div id="error"></div>

      <p>Note: against the principles of web architecture and good sense,
      passwords are transmitted in the clear. Bear that in mind.</p>

    </div>

    <h2>Existing users</h2>
    <ul>
      { for $user in $CONFIG/mla:user 
        let $main := concat($CONFIG/mla:weblog-path,$user/@userid,"/main")
        order by $user/@userid ascending
	return
	  <li>
	    <a href="{$CONFIG/mla:root}{$main}">
	      { string($user/@userid) }
	    </a>
	  </li>
      }
    </ul>
  </body>
</html>
