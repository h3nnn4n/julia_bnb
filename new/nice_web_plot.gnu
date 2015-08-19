#!/usr/bin/gnuplot

#
# Creates a version of a plot, which looks nice for inclusion on web pages
#
# AUTHOR: Hagen Wierstorf
# Edit  : Renan S. Silva

reset

set terminal pngcairo size 800,600 enhanced font 'Verdana,9'
set output 'htime.png'

set style line 11 lc rgb '#808080' lt 1
set border 3 back ls 11
set tics nomirror
set style line 12 lc rgb '#808080' lt 0 lw 1

set grid back ls 12

set style line 1 lc rgb '#8b1a0e' pt 1 ps 1 lt 1 lw 2 # --- red
set style line 2 lc rgb '#5e9c36' pt 2 ps 1 lt 1 lw 2 # --- green
set style line 3 lc rgb '#65393d' pt 3 ps 1 lt 1 lw 2 # --- brown
set style line 4 lc rgb '#3db7c2' pt 4 ps 1 lt 1 lw 2 # --- blue
set style line 5 lc rgb '#f9c386' pt 5 ps 1 lt 1 lw 2 # --- blue
set style line 6 lc rgb '#98cdc5' pt 6 ps 1 lt 1 lw 2 # --- grey-cyan-thing

#set logscale y

set xrange [100:3250]
set yrange [0  :1500]

set key top left

set xlabel 'Tamanho'
set ylabel 'Tempo'

a2 = 10
a3 = 10
a4 = 10
a6 = 10

b2 = 5
b3 = 5
b4 = 5
b6 = 5

c2 = 0.001
c3 = 0.001
c4 = 0.001
c6 = 0.001

d2 = 1
d3 = 1
d4 = 1
d6 = 1

f2(x) = a2 + exp(b2 + x * c2) * d2 
f3(x) = a3 + exp(b3 + x * c3) * d3 
f4(x) = a4 + exp(b4 + x * c4) * d4 
f6(x) = a6 + exp(b6 + x * c6) * d6 

fit f2(x) 'data2.log'       using 1:2 via a2, b2, c2, d2
fit f3(x) 'data3_5x.log'    using 1:2 via a3, b3, c3, d3
fit f4(x) 'data4_25x.log'   using 1:2 via a4, b4, c4, d4
fit f6(x) 'data6_100x.log'  using 1:2 via a6, b6, c6, d6

#plot    'data2.log'      using 1:2 title 'x1'   with points ls 1, \
        #'data3_5x.log'   using 1:2 title 'x5'   with points ls 2, \
        #'data4_25x.log'  using 1:2 title 'x25'  with points ls 3, \
        #'data6_100x.log' using 1:2 title 'x100' with points ls 4

plot    f2(x)                      title 'x1'   with lines  ls 1, \
        f3(x)                      title 'x5'   with lines  ls 2, \
        f4(x)                      title 'x50'  with lines  ls 3, \
        f6(x)                      title 'x100' with lines  ls 4

#plot    'data2.log'      using 1:2 title 'x1'   with points ls 1, \
        #'data3_5x.log'   using 1:2 title 'x5'   with points ls 2, \
        #'data4_25x.log'  using 1:2 title 'x25'  with points ls 3, \
        #'data6_100x.log' using 1:2 title 'x100' with points ls 4, \
        #f2(x)                      notitle      with lines  ls 1, \
        #f3(x)                      notitle      with lines  ls 2, \
        #f4(x)                      notitle      with lines  ls 3, \
        #f6(x)                      notitle      with lines  ls 4
                                      
#
#
#
#
