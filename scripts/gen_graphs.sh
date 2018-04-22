#!/bin/bash

WIDTH=1920
HEIGHT=1080
FORMAT=PNG
FILE_FORMAT=png
OPTIONS="-D --font DEFAULT:16"
GRAPH_DATE_INFO="Vygenerovany: dna $(date +%Y-%m-%d) o $(date +%H:%M)"
RRD_FILE=/var/local/gbo.rrd
PVL_FILE=/var/local/pvl.rrd
IMG_PATH=/srv/http/graphs
ZUNNA_MNT=/mnt/zunna/web/graphs
ZUNNA_MNT_ACT=/mnt/zunna_actual/web/graphs

interval=$1

if [ "$interval" == "" ]; then
    echo "specify interval: [actual|day|week|month|year]"
    exit 1

elif [ "$interval" == "actual" ]; then
	START="end-6hour"
    GRAPH_TITLE="Aktualny"

elif [ "$interval" == "day" ]; then
	START="end-1day"
    GRAPH_TITLE="Denny"

elif [ "$interval" == "week" ]; then
	START="end-1week"
    GRAPH_TITLE="Tyzdenny"

elif [ "$interval" == "month" ]; then
	START="end-1month"
    GRAPH_TITLE="Mesacny"

elif [ "$interval" == "year" ]; then
    START="end-1year"
    GRAPH_TITLE="Rocny "
fi

date=$(date +%Y-%m-%d)

GBO_FILENAME="$IMG_PATH/gbo.$FILE_FORMAT"
PV_FILENAME="$IMG_PATH/pv.$FILE_FORMAT"
PI_FILENAME="$IMG_PATH/pi.$FILE_FORMAT"
RELE_FILENAME="$IMG_PATH/rele.$FILE_FORMAT"
E_TODAY_FILENAME="$IMG_PATH/e_today.$FILE_FORMAT"
U_PANEL1_FILENAME="$IMG_PATH/u_panel1.$FILE_FORMAT"
TEMP_FILENAME="$IMG_PATH/temp.$FILE_FORMAT"
THUMB_FILENAME="$IMG_PATH/thumb.$FILE_FORMAT"

# START OF GENERATING #

# THUMBNAIL

if [ "$interval" != "actual" ]; then
    rrdtool graph $THUMB_FILENAME --imgformat $FORMAT \
    --end now --start $START --width 256 --height 256 --only-graph \
    --lower-limit 0 -M \
    DEF:e=$PVL_FILE:e_now:AVERAGE \
    AREA:e#1A1A59 \
    LINE2:e#09093B:"PV" 
fi

# VYKON

rrdtool graph $GBO_FILENAME --imgformat $FORMAT \
--end now --start $START --width $WIDTH --height $HEIGHT $OPTIONS \
--title "$GRAPH_TITLE graf GBO. $GRAPH_DATE_INFO" \
--vertical-label "kW" \
-A \
DEF:i=$RRD_FILE:c0:AVERAGE \
DEF:u=$RRD_FILE:u:AVERAGE \
CDEF:watt=i,u,*,10000,/ \
CDEF:watts_in=watt,0,GT,0,watt,IF \
AREA:watts_in#FF5555 \
CDEF:watts_out=watt,0,LT,0,watt,IF \
AREA:watts_out#55FF55 \
VDEF:max_in=watts_in,MINIMUM \
VDEF:max_out=watts_out,MAXIMUM \
LINE:max_in#FF0000 \
LINE:max_out#00FF00 \
VDEF:last_in=watts_in,LAST \
VDEF:last_out=watts_out,LAST \
CDEF:watts_in_kwh=watts_in,60,/,60,/ \
CDEF:watts_out_kwh=watts_out,60,/,60,/ \
VDEF:total_in=watts_in_kwh,TOTAL \
VDEF:total_out=watts_out_kwh,TOTAL \
LINE2:watts_in#FF0000:"Zo siete" \
GPRINT:last_in:"Posledna hodnota prikonu\: %.2lf kW\t" \
GPRINT:max_in:"Maximalny prikon\: %.2lf kW\t" \
GPRINT:total_in:"Celkova praca\: %.2lf kWh\l" \
LINE2:watts_out#00FF00:"Do siete" \
GPRINT:last_out:"Posledna hodnota vykonu\:   %.2lf kW\t" \
GPRINT:max_out:"Maximalny vykon\:   %.2lf kW\t" \
GPRINT:total_out:"Celkova praca\:  %.2lf kWh\l"

# PI

rrdtool graph $PI_FILENAME --imgformat $FORMAT \
--end now --start $START --width $WIDTH --height $HEIGHT $OPTIONS \
--title "$GRAPH_TITLE graf PI. $GRAPH_DATE_INFO" \
--vertical-label "%" \
--lower-limit 0 -M \
DEF:pi=$RRD_FILE:pi:AVERAGE \
VDEF:min=pi,MINIMUM \
VDEF:max=pi,MAXIMUM \
VDEF:last=pi,LAST \
VDEF:avg=pi,AVERAGE \
LINE:max#044170 \
LINE2:100#000000 \
LINE2:pi#044170:"PI" \
AREA:pi#0874C7 \
GPRINT:last:"Posledna hodnota PI\: %.1lf%%\t" \
GPRINT:max:"Maximalna hodnota PI\: %.1lf%%\t" \
GPRINT:min:"Minimalna hodnota PI\: %.1lf%%\t" \
GPRINT:avg:"Priemerna hodnota PI\: %.1lf%%"

# RELE

rrdtool graph $RELE_FILENAME --imgformat $FORMAT \
--end now --start $START --width $WIDTH --height $HEIGHT $OPTIONS \
--title "$GRAPH_TITLE graf rele. $GRAPH_DATE_INFO" \
--lower-limit 0 -M \
DEF:k=$RRD_FILE:k:AVERAGE \
VDEF:last=k,LAST \
VDEF:avg=k,AVERAGE \
LINE2:1#303030 \
LINE2:k#000000:"Rele" \
AREA:k#303030 \
GPRINT:last:"Posledna hodnota Rele\: %.1lf\t" \
GPRINT:avg:"Priemerna hodnota Rele\: %.1lf"

# PV

rrdtool graph $PV_FILENAME --imgformat $FORMAT \
--end now --start $START --width $WIDTH --height $HEIGHT $OPTIONS \
--title "$GRAPH_TITLE graf PV. $GRAPH_DATE_INFO" \
--vertical-label "W" \
--lower-limit 0 -M \
DEF:e=$PVL_FILE:e_now:AVERAGE \
VDEF:max_e=e,MAXIMUM \
VDEF:last=e,LAST \
CDEF:total_in_kwh=e,60,/,60,/ \
VDEF:total=total_in_kwh,TOTAL \
AREA:e#123652 \
LINE2:e#042037:"PV" \
LINE:max_e#042037 \
GPRINT:max_e:"Max hodnota PV\: %.2lf W\t" \
GPRINT:last:"Posledna hodnota PV\: %.2lf W\t" \
GPRINT:total:"Celkova praca\:  %.2lf Wh"

# TEMP

rrdtool graph $TEMP_FILENAME --imgformat $FORMAT \
--end now --start $START --width $WIDTH --height $HEIGHT $OPTIONS \
--title "$GRAPH_TITLE graf teploty. $GRAPH_DATE_INFO" \
--vertical-label "degrees C" \
--lower-limit 0 -M \
DEF:t_raw=$PVL_FILE:temp:AVERAGE \
CDEF:t=t_raw,10,/ \
VDEF:t_max=t,MAXIMUM \
VDEF:t_last=t,LAST \
AREA:t#FF0000#FFFA00:gradheight=600 \
LINE2:t#FF0000:"Temp" \
LINE:t_max#00FF00 \
GPRINT:t_max:"Max hodnota \: %.2lf C\t" \
GPRINT:t_last:"Posledna hodnota \: %.2lf C"

# E_TODAY

rrdtool graph $E_TODAY_FILENAME --imgformat $FORMAT \
--end now --start $START --width $WIDTH --height $HEIGHT $OPTIONS \
--title "$GRAPH_TITLE graf vyprodukovanej prace. $GRAPH_DATE_INFO" \
--vertical-label "kWh" \
--lower-limit 0 -M \
DEF:x_raw=$PVL_FILE:e_today:AVERAGE \
CDEF:x=x_raw,10,* \
VDEF:x_max=x,MAXIMUM \
VDEF:x_last=x,LAST \
AREA:x#009200 \
LINE2:x#007000:"e_today" \
LINE:x_max#007000 \
GPRINT:x_max:"Max hodnota e_today\: %.2lf Wh\t" \
GPRINT:x_last:"Posledna hodnota e_today\: %.2lf Wh"

# UPANEL1

rrdtool graph $U_PANEL1_FILENAME --imgformat $FORMAT \
--end now --start $START --width $WIDTH --height $HEIGHT $OPTIONS \
--title "$GRAPH_TITLE graf napetia. $GRAPH_DATE_INFO" \
--vertical-label "V" \
--lower-limit 0 -M \
DEF:x_raw=$PVL_FILE:u_panel1:AVERAGE \
CDEF:x=x_raw,10,/ \
VDEF:x_max=x,MAXIMUM \
VDEF:x_last=x,LAST \
AREA:x#3D1E02 \
LINE2:x#1F0E00:"u_panel1" \
LINE:x_max#1F0E00 \
GPRINT:x_max:"Max hodnota u\: %.2lf V\t" \
GPRINT:x_last:"Posledna hodnota u\: %.2lf V"

# END OF GENERATING #

# UPLOADING

cd $IMG_PATH

if [ "$interval" == "actual" ]; then

    echo "START: uploading $interval graphs to zunna..."

    echo "KdppcdS16453" | sshfs mrx.zunna.sk@zunna.sk:/ /mnt/zunna_actual/ -o password_stdin

    cp $GBO_FILENAME $ZUNNA_MNT_ACT/actual
    cp $PV_FILENAME $ZUNNA_MNT_ACT/actual
    cp $PI_FILENAME $ZUNNA_MNT_ACT/actual
    cp $RELE_FILENAME $ZUNNA_MNT_ACT/actual
    cp $U_PANEL1_FILENAME $ZUNNA_MNT_ACT/actual
    cp $TEMP_FILENAME $ZUNNA_MNT_ACT/actual
    cp $E_TODAY_FILENAME $ZUNNA_MNT_ACT/actual

    cp $GBO_FILENAME ./actual
    cp $PV_FILENAME ./actual
    cp $PI_FILENAME ./actual
    cp $RELE_FILENAME ./actual
    cp $U_PANEL1_FILENAME ./actual
    cp $TEMP_FILENAME ./actual
    cp $E_TODAY_FILENAME ./actual

    umount /mnt/zunna_actual


else

	echo "START: archiving $interval graphs..."

    ARCH_DIR="$interval/$date"

    echo "KdppcdS16453" | sshfs mrx.zunna.sk@zunna.sk:/ /mnt/zunna/ -o password_stdin
    
    mkdir $ZUNNA_MNT/$ARCH_DIR

    cp $GBO_FILENAME $ZUNNA_MNT/$ARCH_DIR
    cp $PV_FILENAME $ZUNNA_MNT/$ARCH_DIR
    cp $PI_FILENAME $ZUNNA_MNT/$ARCH_DIR
    cp $RELE_FILENAME $ZUNNA_MNT/$ARCH_DIR
    cp $U_PANEL1_FILENAME $ZUNNA_MNT/$ARCH_DIR
    cp $TEMP_FILENAME $ZUNNA_MNT/$ARCH_DIR
    cp $E_TODAY_FILENAME $ZUNNA_MNT/$ARCH_DIR
    cp $THUMB_FILENAME $ZUNNA_MNT/$ARCH_DIR

    umount /mnt/zunna/

    mkdir $ARCH_DIR

    cp $GBO_FILENAME $ARCH_DIR
    cp $PV_FILENAME $ARCH_DIR
    cp $PI_FILENAME $ARCH_DIR
    cp $RELE_FILENAME $ARCH_DIR
    cp $U_PANEL1_FILENAME $ARCH_DIR
    cp $TEMP_FILENAME $ARCH_DIR
    cp $E_TODAY_FILENAME $ARCH_DIR
    cp $THUMB_FILENAME $ARCH_DIR

#	echo "START: pushing to drive $interval_name graphs..."
#	drive push -quiet -destination GBO $IMG_PATH/Archiv/vykon_$interval_name/$date.png
#	drive push -quiet -destination GBO $IMG_PATH/Archiv/pi_$interval_name/$date.png
#	drive push -quiet -destination GBO $IMG_PATH/Archiv/rele_$interval_name/$date.png
#	drive push -quiet -destination GBO $IMG_PATH/Archiv/pv_$interval_name/$date.png
#	echo "done: pushing to drive $interval_name graphs..."

    rm $THUMB_FILENAME
fi

rm $GBO_FILENAME
rm $PV_FILENAME
rm $PI_FILENAME
rm $RELE_FILENAME
rm $U_PANEL1_FILENAME
rm $TEMP_FILENAME
rm $E_TODAY_FILENAME

echo "DONE: Generating $interval graphs..."

exit 0
