#!/bin/bash

step=5
hb=15
let "tyzden = (60/step)*60*24*7"
let "mesiac = (60/step)*60*24*30/5"
let "rok =    (60/step)*60*24*365*2/60"
echo "Step: $step"
echo "Tyzden: $tyzden"
echo "Mesiac: $mesiac"
echo "2 roky: $rok"

rrdtool create /var/local/pvl.rrd --step $step \
DS:temp:GAUGE:$hb:-1000:1000 \
DS:u_panel1:GAUGE:$hb:-1000:1000 \
DS:i_panel1:GAUGE:$hb:-100:100 \
DS:u_panel2:GAUGE:$hb:-1000:1000 \
DS:i_panel2:GAUGE:$hb:-100:100 \
DS:u_panel3:GAUGE:$hb:-1000:1000 \
DS:i_panel3:GAUGE:$hb:-100:100 \
DS:e_today:GAUGE:$hb:0:100000 \
DS:u_grid:GAUGE:$hb:-1000:1000 \
DS:i_grid:GAUGE:$hb:-100:100 \
DS:freq:GAUGE:$hb:0:10000 \
DS:e_now:GAUGE:$hb:0:10000 \
DS:e_total:GAUGE:$hb:0:1000000 \
DS:t_total:GAUGE:$hb:0:1000000 \
RRA:AVERAGE:0.5:1:$tyzden \
RRA:MAX:0.5:1:$tyzden \
RRA:MIN:0.5:1:$tyzden \
RRA:AVERAGE:0.5:5:$mesiac \
RRA:MAX:0.5:5:$mesiac \
RRA:MIN:0.5:5:$mesiac \
RRA:AVERAGE:0.5:60:$rok \
RRA:MAX:0.5:60:$rok \
RRA:MIN:0.5:60:$rok \

echo rrd created.
exit 1
