xquery version "1.0-ml";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace mla="http://www.marklogic.com/ns/atompub";
declare namespace app="http://www.w3.org/2007/app";
declare namespace atom="http://www.w3.org/2005/Atom";

declare option xdmp:mapping "false"; 

let $configuration
  := <configuration xmlns="http://www.marklogic.com/ns/atompub"
                    xmlns:app="http://www.w3.org/2007/app"
		    xmlns:atom="http://www.w3.org/2005/Atom">
       <root>http://localhost:8600</root>
       <edit-root>http://localhost:8601</edit-root>
       <generator>Mark Logic AtomPub V0.5</generator>
       <module method="post">/AtomPub/post.xqy</module>
       <module method="put">/AtomPub/put.xqy</module>
       <module method="validate">/AtomPub/validate.xqy</module>
       <module method="format">/AtomPub/format.xqy</module>
       <weblog-reader>joepublic</weblog-reader>
       <weblog-path>/u/</weblog-path>

       <reserved userid="admin"/>
       <reserved userid="weblog-admin"/>

     </configuration>
return
  if (doc-available("/etc/configuration.xml"))
  then
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>Database is configured</title>
      </head>
      <body>
        <h1>Database is configured</h1>
        <p>You've already run <em>load-config.xqy</em>.</p>
      </body>
    </html>
  else
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>Updating database config files</title>
      </head>
      <body>
        <h1>Updating database config files</h1>
        <ul>
  	{ (xdmp:document-insert("/etc/configuration.xml",
                                  $configuration,
  				(xdmp:permission("weblog-reader", "read"),
  				 xdmp:permission("weblog-admin", "update")),
  			        ()),
  	     <li>Loaded /etc/configuration.xml</li>)
  	}
        </ul>
      </body>
    </html>
