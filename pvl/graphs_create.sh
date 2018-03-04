#!/bin/bash

WIDTH=960
HEIGHT=500
OPTIONS="-A -D"
RRD_FILE=/var/local/gbo.rrd
IMG_PATH=/srv/http/graphs

interval=$1

HOUR=h
START=end-$interval$HOUR

# VYKON

rrdtool graph $IMG_PATH/vykon_$interval.png --imgformat PNG \
--end now --start $START --width $WIDTH --height $HEIGHT $OPTIONS \
--title "Vykon za poslednych $interval hodin" --vertical-label "kW" \
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
--title "Prud za poslednych $interval hodin" --vertical-label "dA" \
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
--title "PI za poslednych $interval hodin" --vertical-label "%" \
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
--title "Napetie za poslednych $interval hodin" --vertical-label "V" \
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

exit 0
