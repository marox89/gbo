#!/bin/bash

WIDTH=1920
HEIGHT=1080
FORMAT=PNG
FILE_FORMAT=png
OPTIONS="-A -D --font DEFAULT:14"
RRD_FILE=/var/local/gbo.rrd
PVL_FILE=/var/local/pvl.rrd
IMG_PATH=/srv/http/graphs

interval=$1

if [ "$interval" == 6 ]; then
	interval_name="aktualne"

elif [ "$interval" == 24 ]; then
	interval_name="denne"

elif [ "$interval" == 168 ]; then
	interval_name="tyzdenne"

elif [ "$interval" == 672 ]; then
	interval_name="mesacne"
fi

date=$(date +%Y-%m-%d-%H-%M)

HOUR=h
START=end-$interval$HOUR

# TEMP

rrdtool graph $IMG_PATH/temp_$interval.$FILE_FORMAT --imgformat $FORMAT \
--end now --start $START --width $WIDTH --height $HEIGHT $OPTIONS \
--title "Teplota za poslednych $interval hodin. Vygenerovane: $(date)" \
DEF:t=$PVL_FILE:temp:AVERAGE \
VDEF:t_max=t,MAXIMUM \
VDEF:t_last=t,LAST \
AREA:t#AAFFAA \
LINE2:t#44FF44:"Temp" \
LINE:t_max#00FF00 \
GPRINT:t_max:"Max hodnota \: %lf C\t" \
GPRINT:t_last:"Posledna hodnota \: %lf C\t"

# E_TODAY

rrdtool graph $IMG_PATH/e_today_$interval.$FILE_FORMAT --imgformat $FORMAT \
--end now --start $START --width $WIDTH --height $HEIGHT $OPTIONS \
--title "Denny akumulovany vykon za poslednych $interval hodin. Vygenerovane: $(date)" --vertical-label "kWh" \
--lower-limit 0 \
DEF:x=$PVL_FILE:e_today:AVERAGE \
VDEF:x_max=x,MAXIMUM \
VDEF:x_last=x,LAST \
AREA:x#AAFFAA \
LINE2:x#44FF44:"e_today" \
LINE:x_max#00FF00 \
GPRINT:x_max:"Max hodnota e_today\: %lf Wh\t" \
GPRINT:x_last:"Posledna hodnota e_today\: %lf Wh\t"

# UPANEL1

rrdtool graph $IMG_PATH/u_panel1_$interval.$FILE_FORMAT --imgformat $FORMAT \
--end now --start $START --width $WIDTH --height $HEIGHT $OPTIONS \
--title "Napetie na panely 1 za poslednych $interval hodin. Vygenerovane: $(date)" --vertical-label "V" \
--lower-limit 0 \
DEF:x=$PVL_FILE:u_panel1:AVERAGE \
VDEF:x_max=x,MAXIMUM \
VDEF:x_last=x,LAST \
AREA:x#AAFFAA \
LINE2:x#44FF44:"u_panel1" \
LINE:x_max#00FF00 \
GPRINT:x_max:"Max hodnota u\: %lf v\t" \
GPRINT:x_last:"Posledna hodnota u\: %lf v\t"

# UPLOADING

echo "START: uploading $interval_name graphs to zunna..."

echo "KdppcdS16453" | sshfs mrx.zunna.sk@zunna.sk:/ /mnt/zunna/ -o password_stdin

cd $IMG_PATH
cp ./temp_$interval.png /mnt/zunna/web/graphs
cp ./e_today_$interval.png /mnt/zunna/web/graphs
cp ./u_panel1_$interval.png /mnt/zunna/web/graphs

umount /mnt/zunna

echo "DONE: uploading $interval_name graphs to zunna..."

exit 0

