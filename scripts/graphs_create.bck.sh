#!/bin/bash

WIDTH=1920
HEIGHT=1080
OPTIONS="-A -D --font DEFAULT:16"
RRD_FILE=/var/local/gbo.rrd
IMG_PATH=/srv/http/graphs

interval=$1
date=$(date +%Y-%m-%d)

HOUR=h
START=end-$interval$HOUR


# VYKON

rrdtool graph $IMG_PATH/vykon_$interval.png --imgformat PNG \
--end now --start $START --width $WIDTH --height $HEIGHT $OPTIONS \
--title "Vykon za poslednych $interval hodin. Vygenerovane: $(date)" --vertical-label "kW" \
DEF:i=$RRD_FILE:c0:AVERAGE:step=6 \
DEF:u=$RRD_FILE:u:AVERAGE:step=6 \
CDEF:watt=i,u,*,10000,/ \
CDEF:watts_in=watt,0,GT,0,watt,IF \
AREA:watts_in#FFAAAA \
CDEF:watts_out=watt,0,LT,0,watt,IF \
AREA:watts_out#AAFFAA \
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
LINE1:watts_in#FF0000:"Zo siete" \
GPRINT:last_in:"Posledna hodnota prikonu\: %.4lfkW\t" \
GPRINT:max_in:"Maximalny prikon\: %.4lfkW\t" \
GPRINT:total_in:"Celkova praca\: %.4lfkWh\l" \
LINE1:watts_out#00FF00:"Do siete" \
GPRINT:last_out:"Posledna hodnota vykonu\:   %.4lfkW\t" \
GPRINT:max_out:"Maximalny vykon\:   %.4lfkW\t" \
GPRINT:total_out:"Celkova praca\:  %.4lfkWh\l"

# PRUD

rrdtool graph $IMG_PATH/prud_$interval.png --imgformat PNG \
--end now --start $START --width $WIDTH --height $HEIGHT $OPTIONS \
--title "Prud za poslednych $interval hodin. Vygenerovane: $(date)" --vertical-label "dA" \
DEF:i1=$RRD_FILE:c1:AVERAGE:step=6 \
DEF:i2=$RRD_FILE:c2:AVERAGE:step=6 \
DEF:i3=$RRD_FILE:c3:AVERAGE:step=6 \
VDEF:min1=i1,MINIMUM \
VDEF:min2=i2,MINIMUM \
VDEF:min3=i3,MINIMUM \
VDEF:max1=i1,MAXIMUM \
VDEF:max2=i2,MAXIMUM \
VDEF:max3=i3,MAXIMUM \
VDEF:last1=i1,LAST \
VDEF:last2=i2,LAST \
VDEF:last3=i3,LAST \
VDEF:avg1=i1,AVERAGE \
VDEF:avg2=i2,AVERAGE \
VDEF:avg3=i3,AVERAGE \
LINE1:i1#FF0000:"I1" \
LINE1:i2#00FF00:"I2":STACK \
LINE1:i3#0000FF:"I3":STACK \
AREA:i1#FFAAAA \
AREA:i2#AAFFAA:STACK \
AREA:i3#AAAAFF:STACK \

# PI

rrdtool graph $IMG_PATH/pi_$interval.png --imgformat PNG \
--end now --start $START --width $WIDTH --height $HEIGHT $OPTIONS \
--title "PI za poslednych $interval hodin. Vygenerovane: $(date)" --vertical-label "%" \
DEF:pi=$RRD_FILE:pi:AVERAGE:step=6 \
VDEF:min=pi,MINIMUM \
VDEF:max=pi,MAXIMUM \
VDEF:last=pi,LAST \
VDEF:avg=pi,AVERAGE \
LINE:min#FF0000 \
LINE:max#00FF00 \
LINE2:100#AAAAAA \
LINE1:pi#0000FF:"PI" \
AREA:pi#AAAAFF \
GPRINT:last:"Posledna hodnota PI\: %.1lf%%\t" \
GPRINT:max:"Maximalna hodnota PI\: %.1lf%%\t" \
GPRINT:min:"Minimalna hodnota PI\: %.1lf%%\t" \
GPRINT:avg:"Priemerna hodnota PI\: %.1lf%%\t"

# NAPETIE

rrdtool graph $IMG_PATH/napetie_$interval.png --imgformat PNG \
--end now --start $START --width $WIDTH --height $HEIGHT $OPTIONS \
--title "Napetie za poslednych $interval hodin. Vygenerovane: $(date)" --vertical-label "V" \
--lower-limit 0 \
DEF:u=$RRD_FILE:u:AVERAGE:step=6 \
VDEF:min=u,MINIMUM \
VDEF:max=u,MAXIMUM \
VDEF:last=u,LAST \
VDEF:avg=u,AVERAGE \
LINE:min#FF0000 \
LINE:max#00FF00 \
LINE1:u#0000FF:"U" \
GPRINT:last:"Posledna hodnota U\: %.1lfV\t" \
GPRINT:max:"Max hodnota U\: %.1lfV\t" \
GPRINT:min:"Min hodnota U\: %.1lfV\t" \
GPRINT:avg:"Priemerna hodnota U\: %.1lfV\t"

# RELE

rrdtool graph $IMG_PATH/rele_$interval.png --imgformat PNG \
--end now --start $START --width $WIDTH --height $HEIGHT $OPTIONS \
--title "Stav rele za poslednych $interval hodin. Vygenerovane: $(date)"  \
DEF:k=$RRD_FILE:k:AVERAGE:step=6 \
VDEF:min=k,MINIMUM \
VDEF:max=k,MAXIMUM \
VDEF:last=k,LAST \
VDEF:avg=k,AVERAGE \
LINE:min#FF0000 \
LINE:max#00FF00 \
LINE1:k#FFFF00:"Rele" \
AREA:k#FFFFAA \
GPRINT:last:"Posledna hodnota Rele\: %.1lf\t" \
GPRINT:max:"Max hodnota Rele\: %.1lf\t" \
GPRINT:min:"Min hodnota Rele\: %.1lf\t" \
GPRINT:avg:"Priemerna hodnota Rele\: %.1lf\t"

# INVERTOR

rrdtool graph $IMG_PATH/pv_$interval.png --imgformat PNG \
--end now --start $START --width $WIDTH --height $HEIGHT $OPTIONS \
--title "PV vykon za poslednych $interval hodin. Vygenerovane: $(date)" --vertical-label "W" \
--lower-limit 0 \
DEF:e=/var/local/pvl.rrd:e_now:AVERAGE:step=12 \
VDEF:max_e=e,MAXIMUM \
VDEF:last=e,LAST \
AREA:e#AAFFAA \
LINE2:e#44FF44:"PV" \
LINE:max_e#00FF00 \
GPRINT:max_e:"Max hodnota PV\: %lf W\t" \
GPRINT:last:"Posledna hodnota PV\: %lf W\t"

if [ "$1" == 6 ]; then
	echo "START: uploading $1 graphs to zunna..."

	echo "KdppcdS16453" | sshfs mrx.zunna.sk@zunna.sk:/ /mnt/zunna/ -o password_stdin

	cd $IMG_PATH
	cp ./pv_6.png /mnt/zunna/web/graphs
	cp ./vykon_6.png /mnt/zunna/web/graphs
	cp ./pi_6.png /mnt/zunna/web/graphs
	cp ./rele_6.png /mnt/zunna/web/graphs

	umount /mnt/zunna

	echo "DONE: uploading $1 graphs to zunna..."

elif [ "$1" == 24 ]; then
	echo "START: uploading $1 graphs to zunna..."

	echo "KdppcdS16453" | sshfs mrx.zunna.sk@zunna.sk:/ /mnt/zunna/ -o password_stdin

	cd $IMG_PATH
	cp ./pv_24.png /mnt/zunna/web/graphs
	cp ./vykon_24.png /mnt/zunna/web/graphs
	cp ./pi_24.png /mnt/zunna/web/graphs
	cp ./rele_24.png /mnt/zunna/web/graphs

	umount /mnt/zunna

	echo "DONE: uploading $1 graphs to zunna..."

	cp ./vykon_24.png ./Archiv/vykon_denne/$date.png
	cp ./prud_24.png ./Archiv/prud_denne/$date.png
	cp ./pi_24.png ./Archiv/pi_denne/$date.png
	cp ./napetie_24.png ./Archiv/napetie_denne/$date.png
	cp ./rele_24.png ./Archiv/rele_denne/$date.png

	drive push -quiet -destination GBO $IMG_PATH/Archiv/vykon_denne/$date.png
	drive push -quiet -destination GBO $IMG_PATH/Archiv/prud_denne/$date.png
	drive push -quiet -destination GBO $IMG_PATH/Archiv/pi_denne/$date.png
	drive push -quiet -destination GBO $IMG_PATH/Archiv/napetie_denne/$date.png
	drive push -quiet -destination GBO $IMG_PATH/Archiv/rele_denne/$date.png
elif [ "$1" == 168 ]; then
	echo "START: uploading $1 graphs to zunna..."

	echo "KdppcdS16453" | sshfs mrx.zunna.sk@zunna.sk:/ /mnt/zunna/ -o password_stdin

	cd $IMG_PATH
	cp ./pv_168.png /mnt/zunna/web/graphs
	cp ./vykon_168.png /mnt/zunna/web/graphs
	cp ./pi_168.png /mnt/zunna/web/graphs
	cp ./rele_168.png /mnt/zunna/web/graphs

	umount /mnt/zunna

	echo "DONE: uploading $1 graphs to zunna..."

	cd $IMG_PATH
	cp ./vykon_168.png ./Archiv/vykon_tyzdenne/$date.png
	cp ./prud_168.png ./Archiv/prud_tyzdenne/$date.png
	cp ./pi_168.png ./Archiv/pi_tyzdenne/$date.png
	cp ./napetie_168.png ./Archiv/napetie_tyzdenne/$date.png
	cp ./rele_168.png ./Archiv/rele_tyzdenne/$date.png

	drive push -quiet -destination GBO $IMG_PATH/Archiv/vykon_tyzdenne/$date.png
	drive push -quiet -destination GBO $IMG_PATH/Archiv/prud_tyzdenne/$date.png
	drive push -quiet -destination GBO $IMG_PATH/Archiv/pi_tyzdenne/$date.png
	drive push -quiet -destination GBO $IMG_PATH/Archiv/napetie_tyzdenne/$date.png
	drive push -quiet -destination GBO $IMG_PATH/Archiv/rele_tyzdenne/$date.png
elif [ "$1" == 672 ]; then
	echo "START: uploading $1 graphs to zunna..."

	echo "KdppcdS16453" | sshfs mrx.zunna.sk@zunna.sk:/ /mnt/zunna/ -o password_stdin

	cd $IMG_PATH
	cp ./pv_$1.png /mnt/zunna/web/graphs
	cp ./vykon_$1.png /mnt/zunna/web/graphs
	cp ./pi_$1.png /mnt/zunna/web/graphs
	cp ./rele_$1.png /mnt/zunna/web/graphs

	umount /mnt/zunna

	echo "DONE: uploading $1 graphs to zunna..."

	cd $IMG_PATH
	cp ./vykon_$1.png ./Archiv/vykon_mesacne/$date.png
	cp ./prud_$1.png ./Archiv/prud_mesacne/$date.png
	cp ./pi_$1.png ./Archiv/pi_mesacne/$date.png
	cp ./napetie_$1.png ./Archiv/napetie_mesacne/$date.png
	cp ./rele_$1.png ./Archiv/rele_mesacne/$date.png

	drive push -quiet -destination GBO $IMG_PATH/Archiv/vykon_mesacne/$date.png
	drive push -quiet -destination GBO $IMG_PATH/Archiv/prud_mesacne/$date.png
	drive push -quiet -destination GBO $IMG_PATH/Archiv/pi_mesacne/$date.png
	drive push -quiet -destination GBO $IMG_PATH/Archiv/napetie_mesacne/$date.png
	drive push -quiet -destination GBO $IMG_PATH/Archiv/rele_mesacne/$date.png
else
	echo "Will NOT upload to Google Drive."	
fi

exit 0

