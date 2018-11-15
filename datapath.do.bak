vlib work

vlog datapath.v

vsim datapath

log {/*}

add wave {/*}

force {clk} 0 0ns, 1 1ns -r 2ns

force {is_record} 1 0ns,0 65ns
force {is_play} 0 0ns

force {go} 0 0ns, 1 5ns -r 20ns
force {reset_address} 1 0ns, 0 10ns, 1 80ns, 0 90ns


force {S} 2#10000 5ns, 2#01000 25ns, 2#00100 45ns
force {P} 2#1000 5ns,   2#1100 25ns,  2#0000 45ns


run 65ns
