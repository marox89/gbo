#!/bin/bash

WIDTH=1920
HEIGHT=1080
FORMAT=PNG
FILE_FORMAT=png
OPTIONS="-D --font DEFAULT:16"
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

date=$(date +%Y-%m-%d)
#date=$(date -Iseconds)

HOUR=h
START=end-$interval$HOUR

# VYKON

rrdtool graph $IMG_PATH/vykon_$interval.$FILE_FORMAT --imgformat $FORMAT \
--end now --start $START --width $WIDTH --height $HEIGHT $OPTIONS \
--title "Vykon za poslednych $interval hodin. Vygenerovane: $(date)" --vertical-label "kW" \
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

rrdtool graph $IMG_PATH/pi_$interval.$FILE_FORMAT --imgformat $FORMAT \
--end now --start $START --width $WIDTH --height $HEIGHT $OPTIONS \
--title "PI za poslednych $interval hodin. Vygenerovane: $(date)" --vertical-label "%" \
--lower-limit 0 -M \
DEF:pi=$RRD_FILE:pi:AVERAGE \
VDEF:min=pi,MINIMUM \
VDEF:max=pi,MAXIMUM \
VDEF:last=pi,LAST \
VDEF:avg=pi,AVERAGE \
LINE:max#00FF00 \
LINE2:100#AAAAAA \
LINE2:pi#0000FF:"PI" \
AREA:pi#5555FF \
GPRINT:last:"Posledna hodnota PI\: %.1lf%%\t" \
GPRINT:max:"Maximalna hodnota PI\: %.1lf%%\t" \
GPRINT:min:"Minimalna hodnota PI\: %.1lf%%\t" \
GPRINT:avg:"Priemerna hodnota PI\: %.1lf%%"

# RELE

rrdtool graph $IMG_PATH/rele_$interval.$FILE_FORMAT --imgformat $FORMAT \
--end now --start $START --width $WIDTH --height $HEIGHT $OPTIONS \
--title "Stav rele za poslednych $interval hodin. Vygenerovane: $(date)" \
--lower-limit 0 -M \
DEF:k=$RRD_FILE:k:AVERAGE \
VDEF:last=k,LAST \
VDEF:avg=k,AVERAGE \
LINE2:1#AAAAAA \
LINE2:k#000000:"Rele" \
AREA:k#555555 \
GPRINT:last:"Posledna hodnota Rele\: %.1lf\t" \
GPRINT:avg:"Priemerna hodnota Rele\: %.1lf"

# PV

rrdtool graph $IMG_PATH/pv_$interval.$FILE_FORMAT --imgformat $FORMAT \
--end now --start $START --width $WIDTH --height $HEIGHT $OPTIONS \
--title "PV vykon za poslednych $interval hodin. Vygenerovane: $(date)" --vertical-label "W" \
--lower-limit 0 -M \
DEF:e=$PVL_FILE:e_now:AVERAGE \
VDEF:max_e=e,MAXIMUM \
VDEF:last=e,LAST \
CDEF:total_in_kwh=e,60,/,60,/ \
VDEF:total=total_in_kwh,TOTAL \
AREA:e#55FF55 \
LINE2:e#00FF00:"PV" \
LINE:max_e#00FF00 \
GPRINT:max_e:"Max hodnota PV\: %.2lf W\t" \
GPRINT:last:"Posledna hodnota PV\: %.2lf W\t" \
GPRINT:total:"Celkova praca\:  %.2lf Wh"

# TEMP

rrdtool graph $IMG_PATH/temp_$interval.$FILE_FORMAT --imgformat $FORMAT \
--end now --start $START --width $WIDTH --height $HEIGHT $OPTIONS \
--title "Teplota za poslednych $interval hodin. Vygenerovane: $(date)" \
--lower-limit 0 -M \
DEF:t_raw=$PVL_FILE:temp:AVERAGE \
CDEF:t=t_raw,10,/ \
VDEF:t_max=t,MAXIMUM \
VDEF:t_last=t,LAST \
AREA:t#FF0000#FFFA00:gradheight=300 \
LINE2:t#FF0000:"Temp" \
LINE:t_max#00FF00 \
GPRINT:t_max:"Max hodnota \: %.2lf C\t" \
GPRINT:t_last:"Posledna hodnota \: %.2lf C"

# E_TODAY

rrdtool graph $IMG_PATH/e_today_$interval.$FILE_FORMAT --imgformat $FORMAT \
--end now --start $START --width $WIDTH --height $HEIGHT $OPTIONS \
--title "Denny akumulovany vykon za poslednych $interval hodin. Vygenerovane: $(date)" --vertical-label "kWh" \
--lower-limit 0 -M \
DEF:x_raw=$PVL_FILE:e_today:AVERAGE \
CDEF:x=x_raw,10,* \
VDEF:x_max=x,MAXIMUM \
VDEF:x_last=x,LAST \
AREA:x#55FF55 \
LINE2:x#00FF00:"e_today" \
LINE:x_max#00FF00 \
GPRINT:x_max:"Max hodnota e_today\: %.2lf Wh\t" \
GPRINT:x_last:"Posledna hodnota e_today\: %.2lf Wh"

# UPANEL1

rrdtool graph $IMG_PATH/u_panel1_$interval.$FILE_FORMAT --imgformat $FORMAT \
--end now --start $START --width $WIDTH --height $HEIGHT $OPTIONS \
--title "Napetie na panely 1 za poslednych $interval hodin. Vygenerovane: $(date)" --vertical-label "V" \
--lower-limit 0 -M \
DEF:x_raw=$PVL_FILE:u_panel1:AVERAGE \
CDEF:x=x_raw,10,/ \
VDEF:x_max=x,MAXIMUM \
VDEF:x_last=x,LAST \
AREA:x#55FF55 \
LINE2:x#00FF00:"u_panel1" \
LINE:x_max#00FF00 \
GPRINT:x_max:"Max hodnota u\: %.2lf V\t" \
GPRINT:x_last:"Posledna hodnota u\: %.2lf V"
# UPLOADING

echo "START: uploading $interval_name graphs to zunna..."

echo "KdppcdS16453" | sshfs mrx.zunna.sk@zunna.sk:/ /mnt/zunna/ -o password_stdin

cd $IMG_PATH
cp ./pv_$interval.png /mnt/zunna/web/graphs
cp ./vykon_$interval.png /mnt/zunna/web/graphs
cp ./pi_$interval.png /mnt/zunna/web/graphs
cp ./rele_$interval.png /mnt/zunna/web/graphs
cp ./u_panel1_$interval.png /mnt/zunna/web/graphs
cp ./temp_$interval.png /mnt/zunna/web/graphs
cp ./e_today_$interval.png /mnt/zunna/web/graphs

umount /mnt/zunna

echo "DONE: uploading $interval_name graphs to zunna..."

if [ "$interval" != 6 ]; then

	echo "START: archiving $interval_name graphs..."
	cp ./vykon_$interval.png ./Archiv/vykon_$interval_name/$date.png
	cp ./pi_$interval.png ./Archiv/pi_$interval_name/$date.png
	cp ./pv_$interval.png ./Archiv/pv_$interval_name/$date.png
	cp ./rele_$interval.png ./Archiv/rele_$interval_name/$date.png
	echo "DONE: archiving $interval_name graphs..."

	echo "START: pushing to drive $interval_name graphs..."
	drive push -quiet -destination GBO $IMG_PATH/Archiv/vykon_$interval_name/$date.png
	drive push -quiet -destination GBO $IMG_PATH/Archiv/pi_$interval_name/$date.png
	drive push -quiet -destination GBO $IMG_PATH/Archiv/rele_$interval_name/$date.png
	drive push -quiet -destination GBO $IMG_PATH/Archiv/pv_$interval_name/$date.png
	echo "done: pushing to drive $interval_name graphs..."
fi

exit 0

