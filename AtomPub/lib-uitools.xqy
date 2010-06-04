(:
 : lib-uitools 
 :
 : Copyright (c)2007 Mark Logic Corporation. All rights reserved.
 :
 : THIS LIBRARY IS NOT COMPLETED YET
 :)

(:~
 : Mark Logic User Interface utilities.
 : Utility functions when using XQuery as your UI layer.
 :
 : @author <a href="mailto:chris.welch@marklogic.com">Chris Welch</a>
 : @requires lib-mlps.xqy
 : @version 2007.01.23
 :
 :)

(: load in our own namespace :)
xquery version "0.9-ml" 
module "http://www.marklogic.com/ps/lib/lib-uitools"
import module namespace mlps="http://www.marklogic.com/ps/lib/lib-mlps" at "lib-mlps.xqy"

(:-- QUERYSTRING FUNCTIONS --:)
(:-- Use these functions as an easy way to pass around and modify
     querystring parameters in your code --:)

define function load-params() as element(params)
{
	(:
	 : Common Params
	 : action:   What action to perform on the page. This should be globally unique.
	 : uri?:     When need to reference a file or directory.
	 : option*:  Modifies the behavior of the action.
	 : status?:  Whether an action was successful ("success"|[errorcode])
	 :)
	
	let $params := 
		<params>
		  {for $i in xdmp:get-request-field-names()
		      return
		  		for $j in xdmp:get-request-field($i)
	    	    	return
			       		if ($i ne "") then
	        		    	element {fn:lower-case($i)} {$j}
	        			else ()
		   }
	    </params>
	return $params
}

define function get-date-params(
    $date as xs:date,
    $start-year-name as xs:QName,
    $start-month-name as xs:QName,
    $start-day-name as xs:QName) as element()*
{
    let $date-string as xs:string := $date
    return
    (
    element {$start-year-name} {fn:substring($date-string,1,4)},
    element {$start-month-name} {fn:substring($date-string,6,2)},
    element {$start-day-name} {fn:substring($date-string,9,2)}
    )
}

(: This method is useful in faceted searching. It will take a parameters element
   and either remove elements, remove elements with specific values or replace
   elements with new values. :)
define function modify-param-set(
	$params as element(), (: The parameters :)
	$set as xs:string, (: The name of the parameter elements to be modified :)
	$remove-values as xs:string*, (: Values to be removed. All values if empty :)
	$new-values as xs:string* (: New values to be inserted. No values inserted if empty :)
	) as element()
{
	let $newParams :=
		<params>
			{$params/*[fn:local-name(.) != $set or (fn:local-name(.) = $set and fn:count($remove-values) > 0 and fn:not(. = $remove-values))]}
			{for $value in $new-values
			return
				element {$set} {$value}}
		</params>
	return $newParams
}

(: This method is useful in faceted searching. It will take a parameters element
   and either remove elements, remove elements with specific values or replace
   elements with new values. :)
define function modify-param-set(
	$params as element(params), (: The parameters :)
	$sets as xs:string*, (: The name of the parameter elements to be modified :)
	$new-params as element()* (: New values to be inserted. No values inserted if empty :)
	) as element(params)
{
	let $newParams :=
		<params>
			{$params/*[fn:not(fn:local-name(.) = $sets)]}
			{$new-params}
		</params>
	return $newParams
}

define function rebuild-querystring () as xs:string
{ rebuild-querystring(()) }
define function rebuild-querystring ($omit as xs:string*) as xs:string
{
  let $variables :=
	  for $field in xdmp:get-request-field-names()
	  let $val   := xdmp:get-request-field($field)
	  return if (fn:not($field = $omit)) then fn:concat($field,"=",$val) else ()
  return fn:string-join($variables, "&")
}

define function build-querystring($params as element(params)) as xs:string
{ build-querystring($params, ()) }
define function build-querystring($params as element(params), $omit as xs:string*) as xs:string
{
	let $args :=
		for $arg in $params/*[if($omit) then fn:not(fn:local-name(.) = $omit) else fn:true()][fn:not(fn:local-name(.) = ("start", "end"))]
		return
		    if ($arg ne "") then
			fn:concat(fn:local-name($arg),"=",fn:data($arg))
            else ()
	return
		fn:string-join(fn:distinct-values($args),"&")
}

define function build-date($year as xs:string?, $month as xs:string?, $day as xs:string?) as xs:date?
{
	if (fn:exists($year) and $year != "" and
		fn:exists($month) and $month != "" and
		fn:exists($day) and $day != "") then
		try {
			xs:date(fn:concat(xs:string(xs:integer($year)),"-",mlps:lead-zero(xs:string(xs:integer($month)),2),"-",mlps:lead-zero(xs:string(xs:integer($day)),2)))
		} catch ($exception) {
			()
		}
	else ()
}

define function create-date-querystring($date as xs:date, $prefix as xs:string) as xs:string
{
	let $parts := fn:tokenize(fn:string($date),"-")
	let $params := fn:concat($prefix,"-year=",$parts[1],"&",$prefix,"-month=",$parts[2],"&",$prefix,"-day=",$parts[3])
	return
		$params
}

(:-- PAGINATION METHODS --:)

define function page-info(
	$page as xs:integer,
	$items-per-page as xs:integer,
	$count as xs:integer) as element(pagination)
{
	if ($count <= 0) then
		<pagination>
			<page>0</page>
			<pages>0</pages>
			<start>0</start>
			<end>0</end>
			<count>0</count>
			<items-per-page>{$items-per-page}</items-per-page>
		</pagination>
	else
		let $pages := fn:ceiling($count div $items-per-page)
		let $page := if ($page < 1) then 1 else if ($page > $pages) then $pages else $page
		let $start := (($page - 1) * $items-per-page) + 1
		let $end := $page * $items-per-page
		let $end := if ($end > $count) then $count else $end
		let $previous := $page - 1
		let $next := $page + 1
		return
		<pagination>
			<page>{$page}</page>
			<pages>{$pages}</pages>
			<start>{$start}</start>
			<end>{$end}</end>
			<count>{$count}</count>
			<items-per-page>{$items-per-page}</items-per-page>
			{if ($previous > 0) then <previous>{$previous}</previous> else ()}
			{if ($next <= $pages and $pages > 1) then <next>{$next}</next> else ()}
		</pagination>
}

(:-- UTILITY METHODS --:)

(: Elements without content will be considered empty :)
define function is-null-or-empty($input as item()*) as xs:boolean
{
	let $value := fn:true()
	return
	(
	for $i in $input
	return xdmp:set($value, $value and (fn:not(fn:exists($i) and fn:normalize-space(fn:string($i)) ne ""))),
	$value
	)
}

define function is-between($num as xs:double, $a as xs:double, $b as xs:double) as xs:boolean
{
    if     ( ($num ge $a) and ($num le $b) ) then fn:true()
    else if( ($num le $a) and ($num ge $b) ) then fn:true()
    else fn:false()
}

