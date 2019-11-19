
* test

net install hoch, from("https://raw.githubusercontent.com/jjchern/hoch/master") replace force

clear
set more off
cd "~/Desktop/hoch/"

use "test_nbr_hoch_ps2.dta", clear

hoch (cost tx) (effect tx)

hoch (cost tx) (effect tx), icer fieller

hoch (cost tx) (effect tx), icer fieller cefig

hoch (cost tx) (effect tx), icer fieller cefig inb lambda(100000)

hoch (cost tx) (effect tx), icer fieller cefig inb lambda(5000)
