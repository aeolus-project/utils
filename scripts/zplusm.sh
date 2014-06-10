#!/bin/bash

# Usage example `basename $0` -u universes/universe-varnish-monotone.json -c configurations/ic-single-location-json-v1.json -s specifications/specification-varnish.spec"

# tools executables
ZEPHYRUS_EXECUTABLE='/home/jacopo/programmi/aeolus/zephyrus/zephyrus.native'
METIS_EXECUTABLE='/home/jacopo/programmi/aeolus/metis/metis.native'

# metis options flags
MANDRIVA_MODE=0
DOT_OUTPUT=0

# temp files
ZEPHYRUS_OUTPUT="/tmp/$$.zephyrus"
METIS_OUTPUT="/tmp/$$.metis"
TMP_ZEPHYRUS_OUTPUT="/tmp/$$.zephyrus.out"
TMP_METIS_OUTPUT="/tmp/$$.metis.out"

function usage_and_exit()
{
    echo "Usage: `basename $0` -u <aelus-universe-file> -c <zephyrus-configuration-file> -s <zephyrus-specification-file>"
    echo -e "\toptional flags"
    echo -e "\t -m : mandriva mode"
    echo -e "\t -d <dot_file> : save the abstract plan in a dot file"
    echo -e "\t -z <dot_file> : save final configuration"
    echo -e "\t -p <dot_file> : save plan"
    exit
}

################################
# process options
################################
while getopts u:c:s:md:hp:z: flag
do
  case "$flag" in
    u) 	  UNIVERSE_FILE="$OPTARG";;
    c)    CONFIGURATION_FILE="$OPTARG";;
    s)    SPECIFICATION_FILE="$OPTARG";;
    m)    MANDRIVA_MODE=1;;
    d)    DOT_OUTPUT=1; DOT_FILE="$OPTARG";;
    z)    ZEPHYRUS_OUTPUT="$OPTARG";;
    p)    METIS_OUTPUT="$OPTARG";;
    h)    usage_and_exit;;
    [?])  usage_and_exit;;
  esac
done

if [[ -z "$UNIVERSE_FILE" || -z "$CONFIGURATION_FILE" || -z "$SPECIFICATION_FILE" ]];
then
    echo "Missing a required parameter (universe, configuration, or specificaiton file)"
    usage_and_exit
fi

if [ ! [ -e $UNIVERSE_FILE && -e $CONFIGURATION_FILE && -e $SPECIFICATION_FILE ] ]; then
  echo "A required file does not exist"
  usage_and_exit
fi


################################
# run zephyrus
################################

ZEPHYRUS_COMMAND="$ZEPHYRUS_EXECUTABLE -u $UNIVERSE_FILE -ic $CONFIGURATION_FILE -spec $SPECIFICATION_FILE -opt compact -out stateful-json-v1 $ZEPHYRUS_OUTPUT -stateful on -solver g12"
echo "Running Zephyrus ($ZEPHYRUS_COMMAND)"
$ZEPHYRUS_COMMAND &> $TMP_ZEPHYRUS_OUTPUT

rc=$?
if [[ $rc != 0 ]] ; then
  echo "Zephyrus exited with code $rc"
  cat $TMP_ZEPHYRUS_OUTPUT
  exit $rc
fi

################################
# run metis
################################

METIS_COMMAND="$METIS_EXECUTABLE -u $UNIVERSE_FILE -conf $ZEPHYRUS_OUTPUT -o $METIS_OUTPUT"

# set optional Metis parameters
if [[ $MANDRIVA_MODE == 1 ]]; then
  METIS_COMMAND="$METIS_COMMAND -m"
fi

if [[ $DOT_OUTPUT == 1 ]]; then
  METIS_COMMAND="$METIS_COMMAND -ap $DOT_FILE"
fi

# run Metis
echo "Running Metis ( $METIS_COMMAND )"
$METIS_COMMAND &> $TMP_METIS_OUTPUT

rc=$?
if [[ $rc != 0 ]] ; then
  echo "Metis exited with code $rc\n"
  cat $TMP_METIS_OUTPUT
  exit $rc
fi

################################
# print results
################################
echo "********************************\n"
echo "******Final configuration*******\n"
echo "********************************\n"
cat $ZEPHYRUS_OUTPUT
echo "********************************\n"
echo "*******Final plan***************\n"
echo "********************************\n"
cat $METIS_OUTPUT