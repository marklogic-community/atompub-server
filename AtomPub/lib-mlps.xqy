(:
 : lib-mlps.xqy
 :
 : Copyright (c)2003-2007 Mark Logic Corporation. All rights reserved.
 :
 :)

(:~
 : Mark Logic Professional Services library.
 : This library module implements reusable functions in XQuery.
 :
 : Coordinator:
 : @author <a href="mailto:michael.blakeley@marklogic.com">Michael Blakeley</a>
 :
 : Contributers (by last name):
 : @author <a href="mailto:William.LaForest@marklogic.com">William LaForest</a>
 : @author <a href="mailto:chris.welch@marklogic.com">Chris Welch</a>
 :
 : @requires MarkLogic Server 3.1-1
 : @version 3.1-2007-03-23.1
 :
 :)
xquery version "0.9-ml"  
module "http://www.marklogic.com/ps/lib/lib-mlps"

(: we don't want to have to prefix the fn:* functions :)
default function namespace = "http://www.w3.org/2003/05/xpath-functions"

declare namespace mlps = "http://www.marklogic.com/ps/lib/lib-mlps"
declare namespace qm = "http://marklogic.com/xdmp/query-meters"

(: TODO xqdoc :)

(:~ @private :)
define variable $DEBUG as xs:boolean { false() }

(:~ English month names, in upper-case :)
define variable $MONTHS as xs:string+ {
  "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
  "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER" }

(:~ English three-letter month names, in upper-case :)
define variable $SHORT-MONTHS as xs:string+ {
  "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
  "JUL", "AUG", "SEP", "OCT", "NOV", "DEC" }

(:~ regex delimiter for stop-characters in a date pattern :)
define variable $DATE-DELIM as xs:string { "(\s+|[-/\.]+)" }

(:~ regex for month-day :)
define variable $DATE-MONTHDAY-PAT as xs:string { "[0123]?\d" }

(:~ regex for numeric years :)
define variable $DATE-YEAR-PAT as xs:string { "(\d+)" }

(:~ @private :)
define variable $UNIQUE-DELIM as xs:string { string(xdmp:random()) }

(: I'd put this junk into an XML document, but it wouldn't help much,
 : since we'd still have to define the function-handlers
 :)
define variable $DATE-ISO-8601-BASE-PAT as xs:string {
  (: 1759-07-11-07, allowing for tz :)
  concat($DATE-YEAR-PAT, "-\d\d-[0123]\d([-+]\d\d:\d\d)?") }

(:~ regex to match an XML Schema (ISO-8601) date :)
define variable $DATE-ISO-8601-PAT as xs:string {
  concat("\b", $DATE-ISO-8601-BASE-PAT, "\b") }

define variable $DATE-MM-DD-YYYY-PAT as xs:string {
  (: 2006-09-09, but the month-date are ambiguous! :)
  concat("\b", "(\d\d?)-(\d\d?)-", $DATE-YEAR-PAT, "\b")
}

define variable $DATE-EN-US-PAT as xs:string {
  (: JULY 11, 1759 :)
  concat(
    "(", string-join($MONTHS, "|"), ")",
    $DATE-DELIM, "(", $DATE-MONTHDAY-PAT, "),", $DATE-DELIM, $DATE-YEAR-PAT) }

define variable $DATE-EN-US-SHORT-PAT as xs:string {
  (: JUL 11, 1759 :)
  concat(
    "(", string-join($SHORT-MONTHS, "|"), ")",
    $DATE-DELIM, "(", $DATE-MONTHDAY-PAT, "),", $DATE-DELIM, $DATE-YEAR-PAT) }

define variable $DATE-EN-EU-PAT as xs:string {
  (: 11. JULY 1759 or 11-JULY-1759 :)
  concat(
    "(", $DATE-MONTHDAY-PAT, ")\.?", $DATE-DELIM,
    "(", string-join($MONTHS, "|"), "),?",
    $DATE-DELIM, $DATE-YEAR-PAT) }

(: 11. JUL 1759 or 11-JUL-1759 :)
define variable $DATE-EN-EU-SHORT-PAT as xs:string {
  concat(
    "(", $DATE-MONTHDAY-PAT, ")\.?", $DATE-DELIM,
    "(", string-join($SHORT-MONTHS, "|"), "),?",
    $DATE-DELIM, $DATE-YEAR-PAT) }

define variable $TIME-DELIM as xs:string { "(:)" }

(:~ regex to match an XML Schema (ISO-8601) time :)
(: 13:45:59-07, allowing for optional tz and millis :)
define variable $TIME-ISO-8601-PAT as xs:string {
  "^\d\d:\d\d:\d\d(\.\d+)?([-+]\d\d:\d\d)?$" }

(: 12:45 pm, 1pm, may have seconds :)
define variable $TIME-HH-MM-SS-12H-PAT as xs:string {
  "(\d|1[012]):?(\d\d)?:?(\d\d)?\s*(AM|PM)" }

(: 01:45, 13:45 - but no seconds, or it'd be iso-8601 :)
define variable $TIME-HH-MM-24H-PAT as xs:string {
  "(\d\d):(\d\d)" }

(:~ regex to match an XML Schema (ISO-8601) date-time :)
define variable $DATETIME-ISO-8601-PAT as xs:string {
  concat($DATE-ISO-8601-BASE-PAT, "T", $TIME-ISO-8601-PAT) }

(: TODO what about "Mon Jul 17 16:16:05 PDT 2006"? :)

(:~ sample map of English time-mappings :)
define variable $TIME-MAPPINGS as element(map) {
  (: note that we take the first match, so order is important! :)
  <map>
    <mapping value="00:00:00">MIDNIGHT</mapping>
    <mapping value="03:00:00">EARLY MORNING</mapping>
    <mapping value="05:00:00">DAWN</mapping>
    <mapping value="06:00:00">MORNING</mapping>
    <mapping value="06:00:00">BREAKFAST</mapping>
    <mapping value="10:00:00">MID-MORNING</mapping>
    <mapping value="11:00:00">ELEVENSES</mapping>
    <mapping value="12:00:00">NOON</mapping>
    <mapping value="12:00:00">LUNCH</mapping>
    <mapping value="13:00:00">AFTERNOON</mapping>
    <mapping value="18:00:00">DUSK</mapping>
    <mapping value="18:00:00">SUPPERTIME</mapping>
    <mapping value="19:00:00">EVENING</mapping>
    <mapping value="22:00:00">NIGHT</mapping>
  </map> }

(:~ string containing the new-line character :)
define variable $NL as xs:string { codepoints-to-string(10) }



(:~ set debugging to true() or false() :)
define function mlps:debug-set($debug as xs:boolean)
as empty() {
  xdmp:set($DEBUG, $debug)
}

(:~ turn debugging on :)
define function mlps:debug-on() as empty() { xdmp:set($DEBUG, true()) }

(:~ turn debugging off :)
define function mlps:debug-off() as empty() { xdmp:set($DEBUG, false()) }

(:~ if debugging is on, send a message to the error log :)
define function mlps:debug($s as item()*)
as empty()
{
  if (not($DEBUG)) then () else
    xdmp:log(text { "DEBUG:",
      if (empty($s)) then "()" else
      for $i in $s return typeswitch($i)
        case node() return xdmp:quote($i)
        case cts:token return xdmp:quote($i)
        default return $i
    })
}

(:~ throw an error with the specified $code, using $s as supporting data. :)
define function mlps:error($code as xs:string, $s as item()*)
 as empty()
{
  error($code, text {
    if (empty($s)) then "()" else
    for $i in $s return typeswitch ($i)
        case node() return xdmp:quote($i)
        case cts:token return xdmp:quote($i)
        default return $i
  } )
}

define function mlps:test($expected as item()*, $actual as item()*,
 $raw as item()?)
as xdt:anyAtomicType
{
  (: deep-equal doesn't work with cts:query items,
   : so we do extra work - bug 3287.
   :)
  let $query := max((
    for $i in ($expected, $actual)
    return $i instance of cts:query
    ))
  return
    if (($query and xdmp:quote($actual) eq xdmp:quote($expected))
      or (not($query) and deep-equal($actual, $expected)))
    then true()
    else concat("ERROR! ",
      if (empty($raw)) then () else concat(xdmp:quote($raw), ": "),
      if (empty($actual)) then "()" else xdmp:quote($actual),
      " ne ", xdmp:quote($expected))
}

define function mlps:test($test as element(mlps:test))
as xdt:anyAtomicType
{
  let $options :=
    <options xmlns="xdmp:eval">
      <isolation>different-transaction</isolation>
    </options>
  let $expected := $test/mlps:expected/node()
  (: is the expected-value an xquery that we must evaluate? :)
  let $expected :=
    if (exists($test/mlps:expected/@eval)
      and xs:boolean($test/mlps:expected/@eval))
    then xdmp:eval($expected, (), $options)
    else $expected
  (: should we construct a new value from the expected value? :)
  let $expected :=
    if (empty($test/mlps:expected/@construct)
      or not(xs:boolean($test/mlps:expected/@construct)))
    then $expected
    else xdmp:eval(concat($test/mlps:expected/@construct,
      "('", $expected, "')"))
  let $actual := xdmp:eval($test/mlps:xquery, (), $options)
  return mlps:test($expected, $actual, string($test/mlps:description))
}

define function mlps:test($tests as element(mlps:tests),
  $sections as xs:string*)
as xdt:anyAtomicType*
{
  for $t in $tests/mlps:test
    [ empty($sections) or cts:contains(text { $sections }, @section) ]
  return mlps:test($t)
}

define function mlps:time($query as xs:string,
  $iterations as xs:integer, $args as item()*)
  as xdt:dayTimeDuration
{
  let $start := data(xdmp:query-meters()/qm:elapsed-time)
  let $dummy :=
    for $i in (1 to $iterations)
    let $d := xdmp:eval($query, $args)
    return ()
  return (xdmp:query-meters()/qm:elapsed-time - $start) div $iterations
}

(: TODO generic pagination helper, using cts:remainder() :)

(:~
 : The XPath builtin operators for sequences use 'is' tests.
 : To use 'equals', we have to do it ourselves.
 : This function is based on the w3c non-normative examples.
 :)
define function mlps:except
($a as node()*, $b as node()*) as node()*
{
  if (empty($a)) then $b else
  distinct-nodes($a)[ not($b = .) ]
}

(:~
 : The XPath builtin operators for sequences use 'is' tests.
 : To use 'equals', we have to do it ourselves.
 : This function is based on the w3c non-normative examples.
 :)
define function mlps:intersect
($a as node()*, $b as node()*) as node()*
{
  if (empty($b) or empty($a)) then () else
  distinct-nodes($a)[ $b = . ]
}

(:~
 : The XPath builtin operators for sequences use 'is' tests.
 : To use 'equals', we have to do it ourselves.
 : This function is based on the w3c non-normative examples.
 :)
define function mlps:union
($a as node()*, $b as node()*) as node()*
{
  distinct-nodes(($a, $b))
}

(:~ Convert a sequence of hex digits to a string :)
define function mlps:hex-to-string
($hex as xs:string*) as xs:string? {
  if (empty($hex)) then ()
  else codepoints-to-string(
    for $h in $hex return xdmp:hex-to-integer($h)
  )
}

(:~ Pad a numeric string $int with leading zeros
 :  for a total length of up to $size :)
define function mlps:lead-zero
($int as xs:string, $size as xs:integer) as xs:string
{
  let $length := string-length($int)
  return
    if ($length lt $size)
    then concat(string-pad("0", $size - $length), $int)
    else $int
}

(:~ @public convert a human-readable time to xs:time :)
define function mlps:to-iso8601-time($raw as xs:string)
as xs:time?
{
  let $raw := normalize-space(upper-case($raw))
  return
    (: first, see if it is already there :)
    if (matches($raw, $TIME-ISO-8601-PAT)) then xs:time($raw)
    else if (matches($raw, $TIME-HH-MM-SS-12H-PAT)) then
      let $pat := $TIME-HH-MM-SS-12H-PAT
      for $i in mlps:trim-replace($raw, $pat)
      let $h := mlps:lead-zero(replace($i, $TIME-HH-MM-SS-12H-PAT, "$1"), 2)
      let $m := (replace($i, $TIME-HH-MM-SS-12H-PAT, "$2")[.], "00")[1]
      let $s := (replace($i, $TIME-HH-MM-SS-12H-PAT, "$3")[.], "00")[1]
      let $day-night := replace($i, $TIME-HH-MM-SS-12H-PAT, "$4")
      let $h :=
        if ($day-night eq "PM") then string(12 + xs:int($h)) else $h
      return xs:time(string-join(($h, $m, $s), ':'))
    else if (matches($raw, $TIME-HH-MM-24H-PAT)) then
      let $h := mlps:lead-zero(replace($raw, $TIME-HH-MM-24H-PAT, "$1"), 2)
      let $m := (replace($raw, $TIME-HH-MM-24H-PAT, "$2")[.], "00")[1]
      let $s := "00"
      return xs:time(string-join(($h, $m, $s), ':'))
    else
      (: go lateral, returning () as a side-effect if we fail :)
      let $raw := text { $raw }
      let $match := ($TIME-MAPPINGS/mapping[ cts:contains($raw, .) ])[1]
      where $match
      return xs:time($match/@value)
}

(:~ @public convert a human-readable time to xs:date :)
define function mlps:to-iso8601-date($raw as xs:string)
as xs:date?
{
  let $raw := normalize-space(upper-case($raw))
  return
    (: first, see if it is already there :)
    if (matches($raw, $DATE-ISO-8601-PAT)) then xs:date($raw)
    (: NOTE - remember that DATE-DELIM counts as a group! :)
    else if (matches($raw, $DATE-EN-US-PAT)) then
      let $y := replace($raw, $DATE-EN-US-PAT, "$5")
      let $y :=
        (: handle 2-digit years via pre-y2k fix :)
        if (string-length($y) eq 2) then 1900 + xs:int($y) else $y
      let $m := replace($raw, $DATE-EN-US-PAT, "$1")
      let $m := mlps:lead-zero(string(index-of($MONTHS, $m)), 2)
      let $d := replace($raw, $DATE-EN-US-PAT, "$3")
      return xs:date(string-join(($y, $m, $d), "-"))
    else if (matches($raw, $DATE-EN-US-SHORT-PAT)) then
      let $y := replace($raw, $DATE-EN-US-SHORT-PAT, "$5")
      let $y :=
        (: handle 2-digit years via pre-y2k fix :)
        if (string-length($y) eq 2) then 1900 + xs:int($y) else $y
      let $m := replace($raw, $DATE-EN-US-SHORT-PAT, "$1")
      let $m := mlps:lead-zero(string(index-of($SHORT-MONTHS, $m)), 2)
      let $d := replace($raw, $DATE-EN-US-SHORT-PAT, "$3")
      return xs:date(string-join(($y, $m, $d), "-"))
    else if (matches($raw, $DATE-EN-EU-PAT)) then
      let $y := replace($raw, $DATE-EN-EU-PAT, "$5")
      let $y :=
        (: handle 2-digit years via pre-y2k fix :)
        if (string-length($y) eq 2) then 1900 + xs:int($y) else $y
      let $m := replace($raw, $DATE-EN-EU-PAT, "$3")
      let $m := mlps:lead-zero(string(index-of($MONTHS, $m)), 2)
      let $d := replace($raw, $DATE-EN-EU-PAT, "$1")
      return xs:date(string-join(($y, $m, $d), "-"))
    else if (matches($raw, $DATE-EN-EU-SHORT-PAT)) then
      let $pat := $DATE-EN-EU-SHORT-PAT
      for $i in mlps:trim-replace($raw, $pat)
      let $y := replace($i, $DATE-EN-EU-SHORT-PAT, "$5")
      (: handle 2-digit years via pre-y2k fix :)
      let $y :=
        if (string-length($y) eq 2) then 1900 + xs:int($y) else $y
      let $m := replace($i, $DATE-EN-EU-SHORT-PAT, "$3")
      let $m := mlps:lead-zero(string(index-of($SHORT-MONTHS, $m)), 2)
      let $d := replace($i, $DATE-EN-EU-SHORT-PAT, "$1")
      return xs:date(string-join(($y, $m, $d), "-"))
    else if (matches($raw, $DATE-MM-DD-YYYY-PAT)) then
      let $pat := $DATE-MM-DD-YYYY-PAT
      for $i in mlps:trim-replace($raw, $pat)
      let $d := replace($i, $DATE-MM-DD-YYYY-PAT, "$1")
      let $m := replace($i, $DATE-MM-DD-YYYY-PAT, "$2")
      let $y := replace($i, $DATE-MM-DD-YYYY-PAT, "$3")
      return xs:date(string-join(($y, $m, $d), "-"))
    (: sorry, we couldn't find anything :)
    else ()
}

(: return a sequence of matches from a larger string :)
define function mlps:trim-replace($s as xs:string, $pat as xs:string,
  $flags as xs:string)
as xs:string*
{
  if (not(matches($s, $pat, $flags))) then () else
    let $repl-pat := concat("(", $pat, ")")
    let $repl := concat($UNIQUE-DELIM, "$1", $UNIQUE-DELIM)
    return tokenize(replace($s, $repl-pat, $repl, $flags), $UNIQUE-DELIM)
      [matches(., $pat, $flags)]
}

define function mlps:trim-replace($s as xs:string, $pat as xs:string)
as xs:string*
{
  mlps:trim-replace($s, $pat, '')
}

(:
 : convert a Java or other date+time string,
 : such as "12 Dec 2003, 09:10:11 PM", to xs:dateTime
 :)
define function mlps:to-iso8601-date-time($raw as xs:string?)
as xs:dateTime?
{
  mlps:to-iso8601-datetime($raw)
}

define function mlps:to-iso8601-datetime($raw as xs:string?)
as xs:dateTime?
{
  mlps:to-iso8601-dateTime($raw)
}

define function mlps:to-iso8601-dateTime($raw as xs:string?)
as xs:dateTime?
{
  let $raw := normalize-space(upper-case($raw))
  return
    (: first, see if it is already there :)
    if (matches($raw, $DATETIME-ISO-8601-PAT))
    then xs:dateTime($raw)
    else
      (: rely on the individual components,
       : as long as we can at least get a date.
       :)
      let $date := mlps:to-iso8601-date($raw)
      let $time := mlps:to-iso8601-time($raw)
      where $date
      return xs:dateTime(string-join((string($date), string($time)), "T"))
}

(:~ use an element $params as if it were a hash-map :)
define function mlps:append-param($params as element(),
  $n as element()*)
as element()
{
  if (empty($n)) then $params
  else element { node-name($params) } { $params/*, $n }
}

(:~ use an element $params as if it were a hash-map :)
define function mlps:set-param($params as element(), $n as element()*)
as element()
{
  if (empty($n)) then $params
  else element { node-name($params) } {
    let $qname-list :=
      distinct-values(for $e in $n return node-name($e))
    return $params/*[ not(node-name(.) = $qname-list) ],
    $n
  }
}

(:~ resolve a prefix to a the full namespace uri :)
define function mlps:resolve-prefix($prefix as xs:string)
 as xs:string
{
  get-namespace-uri-for-prefix(
    (: create a fake element with the input prefix :)
    element { concat($prefix, ":dummy") } { 1 }, $prefix)
}

(:~
 : set default namespace, or translate existing prefix to default xmlns.
 : if additional prefixes are supplied, append there declarations
 : to the root element.
 :)
define function mlps:set-default-xmlns($n as element(),
 $ns as xs:string, $prefix as xs:string*)
as element() {
  let $ons := namespace-uri($n)
  let $nns := if ($ons eq "") then $ns else $ons
  let $qnm := expanded-QName($nns, local-name($n))
  let $xmlns := mlps:resolve-prefix("xmlns")
  return element {$qnm} {
      for $p in $prefix
      return attribute { expanded-QName($xmlns, $p)}
        { mlps:resolve-prefix($p) },
      for $a in $n/@*[
        namespace-uri(.) != $xmlns
        and empty(index-of($prefix, local-name(.)))
      ]
      return $a,
      if ($nns eq $ns)
      then attribute {expanded-QName("","xmlns")} {$ns}
      else (),
      $n/node()
    }
}

(:~ get the epoch seconds :)
define function mlps:get-epoch-seconds($dt as xs:dateTime)
  as xs:unsignedLong
{
  xs:unsignedLong(xdmp:strftime("%s", $dt))
}

(:~ get the epoch seconds :)
define function mlps:get-epoch-seconds()
  as xs:unsignedLong
{
  mlps:get-epoch-seconds(current-dateTime())
}

(:~ convert epoch seconds to dateTime :)
define function mlps:epoch-seconds-to-dateTime($v)
  as xs:dateTime
{
  xs:dateTime("1970-01-01T00:00:00-00:00")
  + xdt:dayTimeDuration(concat("PT", $v, "S"))
}
