#!/bin/bash

# To use this script execute: swift_provenance-to-opm.sh <database file>

echo Generating OPM for entire sqlite3 database

provdb=$1

rm -f ids.txt
touch ids.txt

mkid() {
  if ! grep --silent "^$1\$" ids.txt  ; then
    echo $1 >> ids.txt
  fi
  echo -n x
  grep -n "^$1\$" ids.txt | cut -f 1 -d ':'
}

mkxmldatetime() {
TZ=UTC date -f %s $1 +"%Y-%m-%dT%H:%M:%SZ"

# this includes the TZ, but not in the correct format for xsd:dateTime
# - xsd dateTime requires a colon separating the TZ hours and minutes
# date -j -f %s $1 +"%Y-%m-%dT%H:%M:%S%z"

}

rm -f opm.xml

echo "<opmGraph xmlns=\"http://openprovenance.org/model/v1.01.a\" xmlns:swift=\"tag:swift-user@ci.uchicago.edu,2008:swift:opm:20090419\">" > opm.xml

# TODO - there are actually many accounts here, if compound procedure
# nesting is regarded as presenting multiple accounts.
# For now, emit everything into a single account, which probably
# violates some (explicit or implicit) integrity rules.
echo "<accounts><account id=\"base\"><value /></account></accounts>" >> opm.xml

echo "<processes>" >> opm.xml

sqlite3 -separator ' ' -batch $provdb "select * from app_exec;"  |
  while read id wf_id app execution_site starttime1 starttime2 duration rest; do
    starttime="$starttime1 $starttime2"
    echo "  <process id=\""$id"q\">"
    echo "    <account id=\"base\" />"
    echo "    <value>"
    echo "    <swift:type>Application Execution</swift:type>"
    echo "    <swift:uri>$id</swift:uri>"
    echo "    <swift:executeinfo starttime=\"$starttime\" duration=\"$duration\" endstate=\"na\" app=\"$app\" scratch=\"na\"/>"
    echo "    </value>"
    echo "  </process>"
  done >> opm.xml

echo "</processes>" >> opm.xml

echo "<artifacts>" >> opm.xml

# we need a list of all artifacts here. for now, take everything we can
# find in the tie-data-invocs and containment tables, uniquefied.
# This is probably the wrong thing to do?

sqlite3 -separator ' ' -batch $provdb "select file_id from file;" >> tmp-dshandles.txt

cat tmp-dshandles.txt | sort | uniq > tmp-dshandles2.txt

while read artifact ; do
echo "  <artifact id=\"$artifact\">"
echo "    <value>"
echo "    <swift:uri>$artifact</swift:uri>"


sqlite3 -separator ' ' -batch $provdb "select name from file where file_id='$artifact';" | while read fn ; do
  echo "<swift:filename>$fn</swift:filename>"
 done


echo "    </value>"
echo "    <account id=\"base\" />"
echo "  </artifact>"
done < tmp-dshandles2.txt >> opm.xml

echo "</artifacts>" >> opm.xml

# this agent is the Swift command-line client
# TODO other agents - the wrapper script invocations at least
echo "<agents>" >> opm.xml
echo "  <agent id=\"swiftclient\"><value/></agent>" >> opm.xml
echo "</agents>" >> opm.xml

echo "<causalDependencies>" >> opm.xml

# other stuff can do this in any order, but here we must probably do it
# in two passes, one for each relation, in order to satisfy schema.
# but for now do it in a single pass...

sqlite3 -separator ' ' -batch $provdb "select * from staged_in;" |
 while read thread dataset; do
    echo "  <used>"
    echo "    <effect id=\"$thread\" />"
    echo "    <role value=\"$variable\" />"
    echo "    <cause id=\"$dataset\" />"
    echo "    <account id=\"base\" />"
    echo "  </used>"
done >> opm.xml

sqlite3 -separator ' ' -batch $provdb "select * from staged_out;" |
 while read thread dataset; do
  echo "  <wasGeneratedBy>"
  echo "    <effect id=\"$dataset\" />"
  echo "    <role value=\"file\" />"
  echo "    <cause id=\"$thread\" />"
  echo "    <account id=\"base\" />"
  echo "  </wasGeneratedBy>"
done >> opm.xml

# attach timings of executes

#sqlite3 -separator ' ' -batch provdb "select * from executes where id='$id';"  | ( read  id starttime duration finalstate app scratch; echo "    <swift:executeinfo starttime=\"$starttime\" duration=\"$duration\" endstate=\"$finalstate\" app=\"$app\" scratch=\"$scratch\"/>" )

# TODO for now, don't put any different between the no-later-than and
# no-earlier-than times. in reality, we know the swift log timestamp
# resolution and can take that into account

sqlite3 -separator ' ' -batch $provdb "select * from app_exec;" | while read id wf_id app site starttime1 starttime2 duration si_duration so_duration scratch ; 
do
  (  starttime="$starttime1 $starttime2"
     echo "<wasControlledBy><effect id=\"$id\"/><role />" ;
     echo "<cause id=\"swiftclient\"/>" ;
     #export XMLSTART=$(mkxmldatetime $starttime);
     echo "<start><noEarlierThan>"$starttime"</noEarlierThan><clockId>swiftclient</clockId></start>" ;
     export unixtime=$(date -d "$starttime" +"%s")
     echo $unixtime
     export E=$(echo $unixtime + $duration | bc -l) ;
     echo "<end><noLaterThan>$(date -u -d @$E +'%Y-%m-%d %H:%M:%S')</noLaterThan><clockId>swiftclient</clockId></end>" ;
     echo "</wasControlledBy>" ) >> opm.xml
done

echo "</causalDependencies>" >> opm.xml


echo "</opmGraph>" >> opm.xml
echo Finished generating OPM, in opm.xml
