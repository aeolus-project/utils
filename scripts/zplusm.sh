#!/bin/bash

ZEPHYRUS_COMMAND='/home/jacopo/programmi/aeolus/zephyrus/zephyrus.native'
METIS_COMMAND='/home/jacopo/programmi/aeolus/metis/metis.native'

if [ "$1" == "-h" ]; then
  echo "Usage: `basename $0` <aelus-universe-file> <zephyrus-configuration-file> <zephyrus-specification-file>\n"
  echo "Example: `basename $0` universes/universe-varnish-monotone.json configurations/ic-single-location-json-v1.json specifications/specification-varnish.spec"
  exit 0
fi

ZEPHYRUS_OUTPUT="$$.zephyrus"
METIS_OUTPUT="$$.metis"

echo "Running Zephyrus ("
echo "$ZEPHYRUS_COMMAND -u $1 -ic $2 -spec $3 -opt compact -out stateful-json-v1 $ZEPHYRUS_OUTPUT -stateful on -solver g12"
echo ")\n"
$ZEPHYRUS_COMMAND -u $1 -ic $2 -spec $3 -opt compact -out stateful-json-v1 $ZEPHYRUS_OUTPUT -stateful on -solver g12

rc=$?
if [[ $rc != 0 ]] ; then
  echo "Zephyrus exited with code $rc\n"
  exit $rc
fi

echo "Running Metis ("
echo "$METIS_COMMAND -u $1 -conf $ZEPHYRUS_OUTPUT -o $METIS_OUTPUT"
echo ")\n"
$METIS_COMMAND -u $1 -conf $ZEPHYRUS_OUTPUT -o $METIS_OUTPUT

rc=$?
if [[ $rc != 0 ]] ; then
  echo "Metis exited with code $rc\n"
  exit $rc
fi

echo "********************************\n"
echo "******Final configuration*******\n"
echo "********************************\n"
cat $ZEPHYRUS_OUTPUT
echo "********************************\n"
echo "*******Final plan***************\n"
echo "********************************\n"
cat $METIS_OUTPUT