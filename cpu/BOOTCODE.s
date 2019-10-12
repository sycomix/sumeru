.global _start
_start:
page_table:
.word   0

.set STATE_RXCMD, 0
.set STATE_RXADDR, 1
.set STATE_RXDATA, 2
.set STATE_TXDATA_DONE, 3

main:
    csrrsi zero,0xf01,1         #set gpio direction         
    csrrsi zero,0xf03,1         #set gpio(0) led
    lui sp, 0x2                 #stack at 0x2000
    la gp, globals              #globals at 0x3000
    lui a0, 0x3                 #set a0 uart buffer to 0x3000
    addi a1, zero, STATE_RXCMD  #use a1 for state
    addi a2, zero, 0            #use a2 fo address pointer

    addi t0, a0, 5              
    csrrw zero, 0xf12, t0       #start uart tx receive(5)

    csrrwi zero, 0xff6, 0       #enable interrutps

mainloop:
    j mainloop                  # this is an interrupt driven program

intr_uart:
    addi t0, zero, STATE_RXCMD
    beq a1, t0, process_cmd 
    addi t0, zero, STATE_TXDATA_DONE
    beq a1, t0, tx_data_done

    # Unknown State Fall Through -- should never happen
    #
    jal zero, panic

restart_rxcmd:
    addi a1, zero, STATE_RXCMD
    addi t0, a0, 5              
    csrrw zero, 0xf12, t0       #start uart tx receive(5)
    jal zero, intr_return

tx_data_done:
    addi a2, a2, 4              # increment address
    jal zero, restart_rxcmd


.set CMD_SETADDR, 0x41 
.set CMD_WRITE, 0x57
.set CMD_READ, 0x52
.set CMD_JMP, 0x4a

process_cmd:
    # Evict uart buffer cache lines 
    csrrw zero, 1, a0

    # Load received bytes 1-5 into t4
    lw t4, 0(a0)
    srli t4, t4, 8
    lw t2, 4(a0)
    slli t2, t2, 24
    or t4, t4, t2

    lb t0, 0(a0)
    addi t1, zero, CMD_SETADDR
    beq t0, t1, cmd_setaddr
    addi t1, zero, CMD_WRITE
    beq t0, t1, cmd_write
    addi t1, zero, CMD_READ
    beq t0, t1, cmd_read
    addi t1, zero, CMD_JMP
    beq t0, t1, cmd_jmp

    csrrci zero, 0xf03, 1       # turn led on -- signalling an error

    # Fall through for unknown command
    # Echo back 0x00000000 signifying error
    #
    sw zero, 0(a0)              #set word in uart buffer
    jal zero, tx_result

cmd_jmp:
    li t0, 0x4a4a4a4a
    bne t0, t4, restart_rxcmd
    fence.i
    csrrwi zero, 0xff6, 0       #enable interrutps
    jalr zero, 0(a2)

cmd_setaddr:
    addi a2, t4, 0              # set address
    sw t4, 0(a0)                # send back address as result
    li t0, 4                    # hack: tx_result will incremenet a2 by 4
    sub a2, a2, t0              #  therefore we reduce a2 by 4 here
    jal zero, tx_result

cmd_write:
    sw t4, 0(a2)                # write data to memory address
    csrrw zero, 0, a2           # flush memory
    sw t4, 0(a0)                # send back write data as result
    jal zero, tx_result

cmd_read:
    csrrsi zero, 0xf03, 1       # turn led off
    lw t0, 0(a2)                        
    sw t0, 0(a0)                #set word in uart buffer
    jal zero, tx_result

tx_result:
    addi a1, zero, STATE_TXDATA_DONE
    csrrw zero, 0, a0           # flush uart buffer cache line
    addi t0, a0, 4
    csrrw zero, 0xf11, t0       #start uart tx transmit
    jal zero, intr_return

intr_timer:
intr_return:
    csrrw t1, 0xff1, zero               
    csrrw zero, 0xff2, t1               
    csrrw zero, 0xfff, zero             

exn_invalid_instr:
exn_pc_align:
panic:
    j panic                     #exn is not handled

.align(8)
globals:
