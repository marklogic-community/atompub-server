0. This module won't run until you perform the steps enumerated here.

1. Change /PATH/TO/WebLog in the lines below (it appears twice!) to
   point to the actual path to the WebLog directory from the
   distribution.

2. If you want the server to work for machines other than the local
   box where the server is running, change http://localhost below to
   the name (or IP address) of the machine on which the server is
   running.

3. If you want to use ports other than 8600 and 8601, change those
   numbers appropriately.

4. If you want to change the names of any of the roles, users,
   databases, or application servers, do that consistently as well.

5. Delete all these lines of instruction, or add an open comment delimiter
   to the beginning of this file. :)

xquery version '1.0-ml';

let $query :=
  "xquery version '1.0-ml';

   declare default function namespace 'http://www.w3.org/2005/xpath-functions';

   import module namespace sec='http://marklogic.com/xdmp/security' at '/MarkLogic/security.xqy';

   declare option xdmp:mapping 'false';

   (sec:create-role('weblog-reader', 'Weblog reader', (), (), ()),
    sec:create-role('weblog-editor', 'Weblog editor', (), (), ()),
    sec:create-role('weblog-admin',  'Weblog administrator', (), (), ()))"
let $opts :=
  <options xmlns="xdmp:eval">
    <database>{xdmp:security-database()}</database>
  </options>
let $results := xdmp:eval($query, (), $opts)
return
  "Created roles."

;

xquery version "1.0-ml";

let $query :=
  "xquery version '1.0-ml';

   declare default function namespace 'http://www.w3.org/2005/xpath-functions';

   import module namespace sec='http://marklogic.com/xdmp/security' at '/MarkLogic/security.xqy';

   declare option xdmp:mapping 'false';

   (sec:privilege-add-roles('http://marklogic.com/xdmp/privileges/unprotected-collections',
                             'execute', ('weblog-reader')),

    sec:privilege-add-roles('http://marklogic.com/xdmp/privileges/xdmp-add-response-header',
                             'execute', ('weblog-reader')),

    sec:privilege-add-roles('http://marklogic.com/xdmp/privileges/xdmp-invoke',
                            'execute', ('weblog-reader')),

    sec:role-set-default-permissions('weblog-reader',
                                     <sec:permission>
                                       <sec:capability>read</sec:capability>
                                       <sec:role-id>
                                         {xs:unsignedLong(sec:get-role-ids('filesystem-access'))}
                                       </sec:role-id>
                                     </sec:permission>),

    sec:role-add-roles('weblog-editor', ('weblog-reader')),

    sec:role-add-roles('weblog-admin', ('weblog-reader')))"
let $opts :=
  <options xmlns="xdmp:eval">
    <database>{xdmp:security-database()}</database>
  </options>
let $results := xdmp:eval($query, (), $opts)
return
  "Added priviliges to roles."

;

xquery version "1.0-ml";

let $query :=
  "xquery version '1.0-ml';

   declare default function namespace 'http://www.w3.org/2005/xpath-functions';

   import module namespace sec='http://marklogic.com/xdmp/security' at '/MarkLogic/security.xqy';

   declare option xdmp:mapping 'false';

   (sec:create-user('joepublic', 'An anonymous weblog reader',
                    xdmp:integer-to-hex(xdmp:random()),
                    ('weblog-reader'), (), ()),

    sec:create-user('weblog-admin', 'The weblog administrator',
                    xdmp:integer-to-hex(xdmp:random()),
                    ('weblog-admin'), (), ()))"
let $opts :=
  <options xmlns="xdmp:eval">
    <database>{xdmp:security-database()}</database>
  </options>
let $results := xdmp:eval($query, (), $opts)
return
  "Created users."

;

xquery version '1.0-ml';

declare default function namespace 'http://www.w3.org/2005/xpath-functions';

import module namespace admin = 'http://marklogic.com/xdmp/admin' at '/MarkLogic/admin.xqy';
import module namespace sec='http://marklogic.com/xdmp/security' at '/MarkLogic/security.xqy';

declare option xdmp:mapping 'false';

let $config     := admin:get-configuration()

let $group-name := xdmp:group-name()
let $groupid    := admin:group-get-id($config, $group-name)

let $config     := admin:forest-create($config, 'weblog', xdmp:host(), ())
let $config     := admin:database-create($config, 'weblog',
                                         xdmp:database('Security'),
                                         xdmp:database('Schemas'))

let $save       := admin:save-configuration($config)

let $wlogdb     := xdmp:database('weblog')
let $config     := admin:database-attach-forest($config, $wlogdb, xdmp:forest('weblog'))

let $config     := admin:http-server-create($config, $groupid, 'weblog-readers', '/PATH/TO/WebLog',
                                            8600, 0, $wlogdb)

let $config     := admin:http-server-create($config, $groupid, 'weblog-editors', '/PATH/TO/WebLog',
                                            8601, 0, $wlogdb)

let $wlogid     := admin:appserver-get-id($config, $groupid, 'weblog-readers')
let $config     := admin:appserver-set-error-handler($config, $wlogid, '/error-handler.xqy')

let $query      := "xquery version '1.0-ml';

                    import module namespace sec='http://marklogic.com/xdmp/security' 
                           at '/MarkLogic/security.xqy';

                    sec:uid-for-name('joepublic')"
let $opts       := <options xmlns='xdmp:eval'>
                     <database>{xdmp:security-database()}</database>
	           </options>
let $uid        := xdmp:eval($query, (), $opts)

let $config     := admin:appserver-set-default-user($config, $wlogid, $uid)
let $config     := admin:appserver-set-authentication($config, $wlogid, "application-level")

let $wlogid     := admin:appserver-get-id($config, $groupid, 'weblog-editors')
let $config     := admin:appserver-set-error-handler($config, $wlogid, '/error-handler.xqy')

let $query      := "xquery version '1.0-ml';

                    import module namespace sec='http://marklogic.com/xdmp/security' 
                           at '/MarkLogic/security.xqy';

                    sec:uid-for-name('nobody')"
let $opts       := <options xmlns='xdmp:eval'>
                     <database>{xdmp:security-database()}</database>
	           </options>
let $uid        := xdmp:eval($query, (), $opts)

let $config := admin:appserver-set-default-user($config, $wlogid, $uid)
let $config := admin:appserver-set-authentication($config, $wlogid, "basic")

let $save    := admin:save-configuration($config)
return
  "Created database and configured web servers."

;

xquery version '1.0-ml';

let $query :=
  "xquery version '1.0-ml';

   declare default function namespace 'http://www.w3.org/2005/xpath-functions';

   import module namespace sec='http://marklogic.com/xdmp/security' at '/MarkLogic/security.xqy';

   declare option xdmp:mapping 'false';

   (sec:create-amp('http://www.marklogic.com/modules/atompub/admin',
                   'create-putative-user', '/AtomPub/admin.xqy',
                   xs:unsignedLong(0), ('admin')),
    sec:create-amp('http://www.marklogic.com/modules/atompub/admin',
                   'create-user', '/AtomPub/admin.xqy',
                   xs:unsignedLong(0), ('admin')))"
let $opts :=
  <options xmlns="xdmp:eval">
    <database>{xdmp:security-database()}</database>
  </options>
let $results := xdmp:eval($query, (), $opts)
return
  "Created amps."

;

xquery version '1.0-ml';

let $query :=
  "xquery version '1.0-ml';

   declare option xdmp:mapping 'false';

   let $configuration
     := <configuration xmlns='http://www.marklogic.com/ns/atompub'>
          <root>http://localhost:8600</root>
          <edit-root>http://localhost:8601</edit-root>
          <generator>Mark Logic AtomPub V0.6</generator>
          <module method='post'>/AtomPub/post.xqy</module>
          <module method='put'>/AtomPub/put.xqy</module>
          <module method='validate'>/AtomPub/validate.xqy</module>
          <module method='format'>/AtomPub/format.xqy</module>
          <weblog-reader>joepublic</weblog-reader>
          <weblog-path>/u/</weblog-path>

          <reserved userid='admin'/>
          <reserved userid='weblog-admin'/>

        </configuration>
   return
     (xdmp:document-insert('/etc/configuration.xml',
                           $configuration,
                           (xdmp:permission('weblog-reader', 'read'),
                           xdmp:permission('weblog-admin', 'update')),
                           ()),
      'Loaded AtomPub configuration.')"
let $wlogdb := xdmp:database('weblog')
let $opts :=
  <options xmlns="xdmp:eval">
    <database>{$wlogdb}</database>
  </options>
return
  xdmp:eval($query, (), $opts)



