<p:declare-step name="main" version="1.0"
                xmlns:xdb="http://nwalsh.com/xpl/docbook"
		xmlns:p="http://www.w3.org/ns/xproc">
<p:input port="parameters" kind="parameter"/>

<p:import href="/Users/ndw/xpl/docbook.xpl"/>

<xdb:html>
  <p:input port="source">
    <p:document href="readme.xml"/>
  </p:input>
  <p:with-param name="docbook.css" select="'main.css'"/>
</xdb:html>

<p:store href="readme.html" method="xhtml" indent="false"/>

</p:declare-step>
