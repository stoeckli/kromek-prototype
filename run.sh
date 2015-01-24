#!/bin/bash +x

# {{{ functions
function die()
{
	echo $1
	exit 4
}

function test_env()
{
	for CMD in "lockrun" "screen" "mv" "cp" "echo" "chmod" "date" "cut" "cat" "fgrep" "tail"
	do
		which ${CMD} || die "${CMD} command not found, exitting."
	done
}

function acquire()
{
	SN=$1
	DEV=$2
	SAMPLE=$3
	SHIELD=$4
	SPE="${SAMPLE}_-_${NOW}_-_${SECONDS}s_-_${SHIELD}_-_${SN}.spe"
	RUN="${SN}.sh"
	#echo "./radangel.py --database --path=${DEV} --capturetime=${SECONDS}" > ${RUN}
	echo "./radangel.py --path=${DEV} --capturetime=${SECONDS}" > ${RUN}
	echo "mv ${SN}_raw.spe ${SPE}" >> ${RUN}
	echo "cp -a ${SPE} spviewer/" >> ${RUN}
	echo "lockrun --lockfile=spviewer/spviewer_list.txt.LOCK --maxtime=5 --wait -- echo '${SPE}, ${SAMPLE} ${HOURS}h ${SHIELD} ${SN} ${NOW}' >> spviewer/spviewer_list.txt" >> ${RUN}
	chmod +x ${RUN}
}
# }}}

test_env

NOW=$(date +%FT%T%z)
DETECTORS=6
# FIXME: HOURS/SECONDS is hardcoded below
HOURS=6
SECONDS=$((${HOURS}*3600))


# FIXME: why this fails?
#screen -dm -S RadAngel -t tailing "tail -n 0 -f [0-9A-F\-]*.csv |cut -d, -f1-7"
screen -dm -S RadAngel -t tailing bash
for SN in $(cat .radangel.conf|fgrep device -A ${DETECTORS}|tail -n ${DETECTORS}|cut -d" " -f3)
do
	DEV=$(cat .radangel.conf|fgrep ${SN}|cut -d" " -f1|tr _ :)
	SAMPLE=$(cat .radangel.conf|fgrep ${SN}|cut -d";" -f2|cut -d":" -f1)
	SHIELD=$(cat .radangel.conf|fgrep ${SN}|cut -d";" -f2|cut -d":" -f2)
	acquire ${SN} ${DEV} ${SAMPLE} ${SHIELD}
	screen -S RadAngel -X screen -t ${SN} "./${SN}.sh"
	sleep 1
	# safe to delete the script, unless debugging
	rm "./${SN}.sh"
done

screen -r RadAngel

# vim: set ts=4 foldmethod=marker :
