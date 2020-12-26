onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /SH2_tb/cpu/CLK
add wave -noupdate /SH2_tb/cpu/CE_R
add wave -noupdate /SH2_tb/cpu/CE_F
add wave -noupdate /SH2_tb/cpu/A
add wave -noupdate /SH2_tb/cpu/DI
add wave -noupdate /SH2_tb/cpu/DO
add wave -noupdate /SH2_tb/cpu/BS_N
add wave -noupdate /SH2_tb/cpu/WE_N
add wave -noupdate /SH2_tb/cpu/RD_N
add wave -noupdate /SH2_tb/cpu/CS0_N
add wave -noupdate -group SBC /SH2_tb/cpu/bsc/IBUS_A
add wave -noupdate -group SBC /SH2_tb/cpu/bsc/IBUS_DI
add wave -noupdate -group SBC /SH2_tb/cpu/bsc/IBUS_DO
add wave -noupdate -group SBC /SH2_tb/cpu/bsc/IBUS_WE
add wave -noupdate -group SBC /SH2_tb/cpu/bsc/IBUS_REQ
add wave -noupdate -group SBC /SH2_tb/cpu/bsc/IBUS_BUSY
add wave -noupdate -group SBC /SH2_tb/cpu/bsc/IBUS_ACT
add wave -noupdate -group SBC /SH2_tb/cpu/bsc/BCR1
add wave -noupdate -group SBC /SH2_tb/cpu/bsc/BCR2
add wave -noupdate -group SBC /SH2_tb/cpu/bsc/WCR
add wave -noupdate -group SBC /SH2_tb/cpu/bsc/MCR
add wave -noupdate -group Cache /SH2_tb/cpu/cache/IBUS_A
add wave -noupdate -group Cache /SH2_tb/cpu/cache/IBUS_DI
add wave -noupdate -group Cache /SH2_tb/cpu/cache/IBUS_DO
add wave -noupdate -group Cache /SH2_tb/cpu/cache/IBUS_WE
add wave -noupdate -group Cache /SH2_tb/cpu/cache/IBADDR
add wave -noupdate -group Cache /SH2_tb/cpu/cache/IBREQ
add wave -noupdate -group Cache /SH2_tb/cpu/cache/IBLOCK
add wave -noupdate -group Cache /SH2_tb/cpu/cache/CACHE_UPDATE
add wave -noupdate -group Cache /SH2_tb/cpu/cache/CACHE_WRITE
add wave -noupdate -group Cache /SH2_tb/cpu/cache/READ_BUSY
add wave -noupdate -group Cache /SH2_tb/cpu/cache/WRITE_BUSY
add wave -noupdate -group Cache /SH2_tb/cpu/cache/IBUS_WRITE
add wave -noupdate -group Cache /SH2_tb/cpu/cache/IBUS_WRITE_PEND
add wave -noupdate -group Cache /SH2_tb/cpu/cache/IBUS_READ
add wave -noupdate -group Cache /SH2_tb/cpu/cache/IBUS_READARRAY
add wave -noupdate -radix hexadecimal /SH2_tb/cpu/core/BUS_A
add wave -noupdate -radix hexadecimal /SH2_tb/cpu/core/BUS_DI
add wave -noupdate /SH2_tb/cpu/core/BUS_DO
add wave -noupdate /SH2_tb/cpu/core/BUS_WR
add wave -noupdate /SH2_tb/cpu/core/BUS_BA
add wave -noupdate /SH2_tb/cpu/core/BUS_REQ
add wave -noupdate /SH2_tb/cpu/core/BUS_WAIT
add wave -noupdate -color Pink -itemcolor Pink /SH2_tb/cpu/core/PC_STALL
add wave -noupdate -color Pink -itemcolor Pink -radix hexadecimal /SH2_tb/cpu/core/PC
add wave -noupdate /SH2_tb/cpu/core/IF_STALL
add wave -noupdate /SH2_tb/cpu/core/NEED_FETCH
add wave -noupdate -color Blue -itemcolor Blue /SH2_tb/cpu/core/ID_STALL
add wave -noupdate /SH2_tb/cpu/core/ID_DELAY_SLOT
add wave -noupdate /SH2_tb/cpu/core/BR_COND
add wave -noupdate -color Blue -itemcolor Blue -expand -subitemconfig {/SH2_tb/cpu/core/PIPE.ID.IR {-color Blue -height 15 -itemcolor Blue} /SH2_tb/cpu/core/PIPE.ID.PC {-color Blue -height 15 -itemcolor Blue}} /SH2_tb/cpu/core/PIPE.ID
add wave -noupdate -color Blue -itemcolor Blue /SH2_tb/cpu/core/ID_DECI
add wave -noupdate -color Blue -itemcolor Blue /SH2_tb/cpu/core/STATE
add wave -noupdate -color Gold -itemcolor Gold /SH2_tb/cpu/core/EX_STALL
add wave -noupdate -color Gold -itemcolor Gold /SH2_tb/cpu/core/BP_A_EXEX
add wave -noupdate -color Gold -itemcolor Gold /SH2_tb/cpu/core/BP_B_EXEX
add wave -noupdate -color Gold -itemcolor Gold /SH2_tb/cpu/core/BP_A_MAEX
add wave -noupdate -color Gold -itemcolor Gold /SH2_tb/cpu/core/BP_B_MAEX
add wave -noupdate -color Gold -itemcolor Gold /SH2_tb/cpu/core/BP_A_WBEX
add wave -noupdate -color Gold -itemcolor Gold /SH2_tb/cpu/core/BP_B_WBEXA
add wave -noupdate -color Gold -itemcolor Gold /SH2_tb/cpu/core/BP_B_WBEXB
add wave -noupdate -color Gold -itemcolor Gold /SH2_tb/cpu/core/BP_A_MALD
add wave -noupdate -color Gold -itemcolor Gold /SH2_tb/cpu/core/BP_B_MALD
add wave -noupdate -color Gold -itemcolor Gold /SH2_tb/cpu/core/BP_A_WBLD
add wave -noupdate -color Gold -itemcolor Gold /SH2_tb/cpu/core/BP_B_WBLD
add wave -noupdate -color Gold -itemcolor Gold -expand -subitemconfig {/SH2_tb/cpu/core/PIPE.EX.IR {-color Gold -height 15 -itemcolor Gold} /SH2_tb/cpu/core/PIPE.EX.DI {-color Gold -height 15 -itemcolor Gold} /SH2_tb/cpu/core/PIPE.EX.PC {-color Gold -height 15 -itemcolor Gold} /SH2_tb/cpu/core/PIPE.EX.RA {-color Gold -height 15 -itemcolor Gold} /SH2_tb/cpu/core/PIPE.EX.RB {-color Gold -height 15 -itemcolor Gold} /SH2_tb/cpu/core/PIPE.EX.R0 {-color Gold -height 15 -itemcolor Gold} /SH2_tb/cpu/core/PIPE.EX.BC {-color Gold -height 15 -itemcolor Gold}} /SH2_tb/cpu/core/PIPE.EX
add wave -noupdate -color Cyan -itemcolor Cyan /SH2_tb/cpu/core/MA_STALL
add wave -noupdate -color Cyan -itemcolor Cyan /SH2_tb/cpu/core/PIPE.MA
add wave -noupdate -color {Green Yellow} -itemcolor {Green Yellow} /SH2_tb/cpu/core/WB_STALL
add wave -noupdate -color {Green Yellow} -itemcolor {Green Yellow} /SH2_tb/cpu/core/PIPE.WB
add wave -noupdate /SH2_tb/cpu/core/RD_SAVE
add wave -noupdate /SH2_tb/cpu/core/PIPE.WB2
add wave -noupdate /SH2_tb/cpu/core/INST_SPLIT
add wave -noupdate /SH2_tb/cpu/core/MA_ACTIVE
add wave -noupdate /SH2_tb/cpu/core/IF_ACTIVE
add wave -noupdate /SH2_tb/cpu/core/MAWB_STALL
add wave -noupdate /SH2_tb/cpu/core/LOAD_SPLIT
add wave -noupdate /SH2_tb/cpu/core/IFID_STALL
add wave -noupdate -color Orange -itemcolor Orange {/SH2_tb/cpu/core/regfile/GR[0]}
add wave -noupdate -color Orange -itemcolor Orange -radix hexadecimal {/SH2_tb/cpu/core/regfile/GR[1]}
add wave -noupdate -color Orange -itemcolor Orange -radix hexadecimal {/SH2_tb/cpu/core/regfile/GR[2]}
add wave -noupdate -color Orange -itemcolor Orange -radix hexadecimal {/SH2_tb/cpu/core/regfile/GR[3]}
add wave -noupdate -group {New Group} -color Orange -itemcolor Orange {/SH2_tb/cpu/core/regfile/GR[4]}
add wave -noupdate -group {New Group} -color Orange -itemcolor Orange {/SH2_tb/cpu/core/regfile/GR[5]}
add wave -noupdate -group {New Group} -color Orange -itemcolor Orange {/SH2_tb/cpu/core/regfile/GR[6]}
add wave -noupdate -group {New Group} -color Orange -itemcolor Orange {/SH2_tb/cpu/core/regfile/GR[7]}
add wave -noupdate -group {New Group} -color Orange -itemcolor Orange {/SH2_tb/cpu/core/regfile/GR[8]}
add wave -noupdate -group {New Group} -color Orange -itemcolor Orange {/SH2_tb/cpu/core/regfile/GR[9]}
add wave -noupdate -group {New Group} -color Orange -itemcolor Orange {/SH2_tb/cpu/core/regfile/GR[10]}
add wave -noupdate -group {New Group} -color Orange -itemcolor Orange {/SH2_tb/cpu/core/regfile/GR[11]}
add wave -noupdate -group {New Group} -color Orange -itemcolor Orange {/SH2_tb/cpu/core/regfile/GR[12]}
add wave -noupdate -group {New Group} -color Orange -itemcolor Orange {/SH2_tb/cpu/core/regfile/GR[13]}
add wave -noupdate -group {New Group} -color Orange -itemcolor Orange {/SH2_tb/cpu/core/regfile/GR[14]}
add wave -noupdate -group {New Group} -color Orange -itemcolor Orange {/SH2_tb/cpu/core/regfile/GR[15]}
add wave -noupdate /SH2_tb/cpu/core/REG_A
add wave -noupdate /SH2_tb/cpu/core/REG_B
add wave -noupdate /SH2_tb/cpu/core/REG_C
add wave -noupdate /SH2_tb/cpu/core/ALU_RES
add wave -noupdate -group MAC /SH2_tb/cpu/MAC_WE
add wave -noupdate -group MAC /SH2_tb/cpu/MAC_SEL
add wave -noupdate /SH2_tb/cpu/core/SR
add wave -noupdate /SH2_tb/cpu/core/SR.T
add wave -noupdate /SH2_tb/cpu/core/VBR
add wave -noupdate -expand /SH2_tb/cpu/core/INTI
add wave -noupdate /SH2_tb/cpu/core/BR_COND
add wave -noupdate /SH2_tb/cpu/IRL_N
add wave -noupdate /SH2_tb/cpu/intc/IRL_REQ
add wave -noupdate /SH2_tb/cpu/intc/IRL_LVL
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {995 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 169
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {2471 ns} {2735 ns}
