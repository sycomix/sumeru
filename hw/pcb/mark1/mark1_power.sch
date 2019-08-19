EESchema Schematic File Version 2
LIBS:power
LIBS:device
LIBS:transistors
LIBS:conn
LIBS:linear
LIBS:regul
LIBS:74xx
LIBS:cmos4000
LIBS:adc-dac
LIBS:memory
LIBS:xilinx
LIBS:microcontrollers
LIBS:dsp
LIBS:microchip
LIBS:analog_switches
LIBS:motorola
LIBS:texas
LIBS:intel
LIBS:audio
LIBS:interface
LIBS:digital-audio
LIBS:philips
LIBS:display
LIBS:cypress
LIBS:siliconi
LIBS:opto
LIBS:atmel
LIBS:contrib
LIBS:valves
LIBS:AlteraFPGA
LIBS:symbols
LIBS:Switch
LIBS:mark1-cache
EELAYER 25 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 2 4
Title "SAKE SOC"
Date "2018-05-30"
Rev "mark1"
Comp "DIYStore India"
Comment1 "Board Power Schematic"
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L GND #PWR01
U 1 1 5B052C99
P 1800 4800
F 0 "#PWR01" H 1800 4550 50  0001 C CNN
F 1 "GND" H 1800 4650 50  0000 C CNN
F 2 "" H 1800 4800 50  0000 C CNN
F 3 "" H 1800 4800 50  0000 C CNN
	1    1800 4800
	1    0    0    -1  
$EndComp
Text GLabel 1100 5350 0    60   Input ~ 0
VCC
$Comp
L EP4CE10E22C8N U4
U 2 1 5B0E2316
P 2150 3200
F 0 "U4" H 2150 5700 60  0000 C CNN
F 1 "EP4CE10E22C8N" H 2150 5600 60  0000 C CNN
F 2 "Housings_QFP:TQFP-144_20x20mm_Pitch0.5mm" H 2300 5900 60  0001 C CNN
F 3 "" H 1150 3550 60  0001 C CNN
	2    2150 3200
	1    0    0    -1  
$EndComp
Text GLabel 3300 1350 2    60   Input ~ 0
VCC1p2
Text GLabel 950  3600 0    60   Input ~ 0
VCC1p2
Text GLabel 950  2700 0    60   Input ~ 0
VCC2p5
$Comp
L GND #PWR02
U 1 1 5B0E2317
P 1800 5750
F 0 "#PWR02" H 1800 5500 50  0001 C CNN
F 1 "GND" H 1800 5600 50  0000 C CNN
F 2 "" H 1800 5750 50  0000 C CNN
F 3 "" H 1800 5750 50  0000 C CNN
	1    1800 5750
	1    0    0    -1  
$EndComp
Text GLabel 2350 5350 2    60   Input ~ 0
VCC3p3
$Comp
L CP C5
U 1 1 5B0E2318
P 2200 5600
F 0 "C5" H 2225 5700 50  0000 L CNN
F 1 "100uF" H 2225 5500 50  0000 L CNN
F 2 "Capacitors_SMD:c_elec_6.3x7.7" H 2238 5450 50  0001 C CNN
F 3 "" H 2200 5600 50  0000 C CNN
	1    2200 5600
	1    0    0    -1  
$EndComp
$Comp
L CP C2
U 1 1 5B0E2319
P 1400 5600
F 0 "C2" H 1425 5700 50  0000 L CNN
F 1 "10uF" H 1425 5500 50  0000 L CNN
F 2 "SMD_Packages:SMD-1206_Pol" H 1438 5450 50  0001 C CNN
F 3 "" H 1400 5600 50  0000 C CNN
	1    1400 5600
	1    0    0    -1  
$EndComp
$Comp
L AP1117 U3
U 1 1 5B0E231A
P 1800 6350
F 0 "U3" H 1900 6100 50  0000 C CNN
F 1 "AMS1117-1.2" H 1800 6600 50  0000 C CNN
F 2 "TO_SOT_Packages_SMD:SOT-223" H 1800 6000 50  0001 C CNN
F 3 "" H 1900 6100 50  0000 C CNN
	1    1800 6350
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR03
U 1 1 5B0E231B
P 1800 6650
F 0 "#PWR03" H 1800 6400 50  0001 C CNN
F 1 "GND" H 1800 6500 50  0000 C CNN
F 2 "" H 1800 6650 50  0000 C CNN
F 3 "" H 1800 6650 50  0000 C CNN
	1    1800 6650
	1    0    0    -1  
$EndComp
Text GLabel 2400 6350 2    60   Input ~ 0
VCC1p2
$Comp
L CP C6
U 1 1 5B0E231C
P 2200 6500
F 0 "C6" H 2225 6600 50  0000 L CNN
F 1 "100uF" H 2225 6400 50  0000 L CNN
F 2 "Capacitors_SMD:c_elec_6.3x7.7" H 2238 6350 50  0001 C CNN
F 3 "" H 2200 6500 50  0000 C CNN
	1    2200 6500
	1    0    0    -1  
$EndComp
Text GLabel 1200 6350 0    60   Input ~ 0
VCC
$Comp
L AP1117 U1
U 1 1 5B0E231D
P 1800 4500
F 0 "U1" H 1900 4250 50  0000 C CNN
F 1 "AMS1117-2.5" H 1800 4750 50  0000 C CNN
F 2 "TO_SOT_Packages_SMD:SOT-223" H 1800 4150 50  0001 C CNN
F 3 "" H 1900 4250 50  0000 C CNN
	1    1800 4500
	1    0    0    -1  
$EndComp
Text GLabel 2400 4500 2    60   Input ~ 0
VCC2p5
$Comp
L CP C4
U 1 1 5B0E231F
P 2200 4650
F 0 "C4" H 2225 4750 50  0000 L CNN
F 1 "100uF" H 2225 4550 50  0000 L CNN
F 2 "Capacitors_SMD:c_elec_6.3x7.7" H 2238 4500 50  0001 C CNN
F 3 "" H 2200 4650 50  0000 C CNN
	1    2200 4650
	1    0    0    -1  
$EndComp
$Comp
L CP C1
U 1 1 5B0E2320
P 1400 4650
F 0 "C1" H 1425 4750 50  0000 L CNN
F 1 "10uF" H 1425 4550 50  0000 L CNN
F 2 "SMD_Packages:SMD-1206_Pol" H 1438 4500 50  0001 C CNN
F 3 "" H 1400 4650 50  0000 C CNN
	1    1400 4650
	1    0    0    -1  
$EndComp
$Comp
L C C7
U 1 1 5B0E2321
P 3950 950
F 0 "C7" H 3975 1050 50  0000 L CNN
F 1 "100nF" H 3975 850 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805_HandSoldering" H 3988 800 50  0001 C CNN
F 3 "" H 3950 950 50  0000 C CNN
	1    3950 950 
	1    0    0    -1  
$EndComp
$Comp
L C C11
U 1 1 5B0E2322
P 4250 950
F 0 "C11" H 4275 1050 50  0000 L CNN
F 1 "100nF" H 4275 850 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805_HandSoldering" H 4288 800 50  0001 C CNN
F 3 "" H 4250 950 50  0000 C CNN
	1    4250 950 
	1    0    0    -1  
$EndComp
$Comp
L C C15
U 1 1 5B0E2323
P 4550 950
F 0 "C15" H 4575 1050 50  0000 L CNN
F 1 "100nF" H 4575 850 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805_HandSoldering" H 4588 800 50  0001 C CNN
F 3 "" H 4550 950 50  0000 C CNN
	1    4550 950 
	1    0    0    -1  
$EndComp
$Comp
L C C17
U 1 1 5B0E2324
P 4850 950
F 0 "C17" H 4875 1050 50  0000 L CNN
F 1 "100nF" H 4875 850 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805_HandSoldering" H 4888 800 50  0001 C CNN
F 3 "" H 4850 950 50  0000 C CNN
	1    4850 950 
	1    0    0    -1  
$EndComp
$Comp
L C C19
U 1 1 5B0E2325
P 5150 950
F 0 "C19" H 5175 1050 50  0000 L CNN
F 1 "100nF" H 5175 850 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805_HandSoldering" H 5188 800 50  0001 C CNN
F 3 "" H 5150 950 50  0000 C CNN
	1    5150 950 
	1    0    0    -1  
$EndComp
$Comp
L C C21
U 1 1 5B0E2326
P 5450 950
F 0 "C21" H 5475 1050 50  0000 L CNN
F 1 "100nF" H 5475 850 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805_HandSoldering" H 5488 800 50  0001 C CNN
F 3 "" H 5450 950 50  0000 C CNN
	1    5450 950 
	1    0    0    -1  
$EndComp
$Comp
L C C23
U 1 1 5B0E2327
P 5750 950
F 0 "C23" H 5775 1050 50  0000 L CNN
F 1 "100nF" H 5775 850 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805_HandSoldering" H 5788 800 50  0001 C CNN
F 3 "" H 5750 950 50  0000 C CNN
	1    5750 950 
	1    0    0    -1  
$EndComp
$Comp
L C C25
U 1 1 5B0E2328
P 6050 950
F 0 "C25" H 6075 1050 50  0000 L CNN
F 1 "100nF" H 6075 850 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805_HandSoldering" H 6088 800 50  0001 C CNN
F 3 "" H 6050 950 50  0000 C CNN
	1    6050 950 
	1    0    0    -1  
$EndComp
Text GLabel 6450 800  2    60   Input ~ 0
VCC1p2
$Comp
L C C8
U 1 1 5B0E2329
P 3950 1500
F 0 "C8" H 3975 1600 50  0000 L CNN
F 1 "100nF" H 3975 1400 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805_HandSoldering" H 3988 1350 50  0001 C CNN
F 3 "" H 3950 1500 50  0000 C CNN
	1    3950 1500
	1    0    0    -1  
$EndComp
$Comp
L C C12
U 1 1 5B0E232A
P 4250 1500
F 0 "C12" H 4275 1600 50  0000 L CNN
F 1 "100nF" H 4275 1400 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805_HandSoldering" H 4288 1350 50  0001 C CNN
F 3 "" H 4250 1500 50  0000 C CNN
	1    4250 1500
	1    0    0    -1  
$EndComp
$Comp
L C C16
U 1 1 5B0E232B
P 4550 1500
F 0 "C16" H 4575 1600 50  0000 L CNN
F 1 "100nF" H 4575 1400 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805_HandSoldering" H 4588 1350 50  0001 C CNN
F 3 "" H 4550 1500 50  0000 C CNN
	1    4550 1500
	1    0    0    -1  
$EndComp
$Comp
L C C18
U 1 1 5B0E232C
P 4850 1500
F 0 "C18" H 4875 1600 50  0000 L CNN
F 1 "100nF" H 4875 1400 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805_HandSoldering" H 4888 1350 50  0001 C CNN
F 3 "" H 4850 1500 50  0000 C CNN
	1    4850 1500
	1    0    0    -1  
$EndComp
$Comp
L C C20
U 1 1 5B0E232D
P 5150 1500
F 0 "C20" H 5175 1600 50  0000 L CNN
F 1 "100nF" H 5175 1400 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805_HandSoldering" H 5188 1350 50  0001 C CNN
F 3 "" H 5150 1500 50  0000 C CNN
	1    5150 1500
	1    0    0    -1  
$EndComp
$Comp
L C C22
U 1 1 5B0E232E
P 5450 1500
F 0 "C22" H 5475 1600 50  0000 L CNN
F 1 "100nF" H 5475 1400 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805_HandSoldering" H 5488 1350 50  0001 C CNN
F 3 "" H 5450 1500 50  0000 C CNN
	1    5450 1500
	1    0    0    -1  
$EndComp
$Comp
L C C24
U 1 1 5B0E232F
P 5750 1500
F 0 "C24" H 5775 1600 50  0000 L CNN
F 1 "100nF" H 5775 1400 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805_HandSoldering" H 5788 1350 50  0001 C CNN
F 3 "" H 5750 1500 50  0000 C CNN
	1    5750 1500
	1    0    0    -1  
$EndComp
$Comp
L C C26
U 1 1 5B0E2330
P 6050 1500
F 0 "C26" H 6075 1600 50  0000 L CNN
F 1 "100nF" H 6075 1400 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805_HandSoldering" H 6088 1350 50  0001 C CNN
F 3 "" H 6050 1500 50  0000 C CNN
	1    6050 1500
	1    0    0    -1  
$EndComp
$Comp
L C C27
U 1 1 5B0E2331
P 6350 1500
F 0 "C27" H 6375 1600 50  0000 L CNN
F 1 "100nF" H 6375 1400 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805_HandSoldering" H 6388 1350 50  0001 C CNN
F 3 "" H 6350 1500 50  0000 C CNN
	1    6350 1500
	1    0    0    -1  
$EndComp
$Comp
L C C28
U 1 1 5B0E2332
P 6650 1500
F 0 "C28" H 6675 1600 50  0000 L CNN
F 1 "100nF" H 6675 1400 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805_HandSoldering" H 6688 1350 50  0001 C CNN
F 3 "" H 6650 1500 50  0000 C CNN
	1    6650 1500
	1    0    0    -1  
$EndComp
$Comp
L C C29
U 1 1 5B0E2333
P 6950 1500
F 0 "C29" H 6975 1600 50  0000 L CNN
F 1 "100nF" H 6975 1400 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805_HandSoldering" H 6988 1350 50  0001 C CNN
F 3 "" H 6950 1500 50  0000 C CNN
	1    6950 1500
	1    0    0    -1  
$EndComp
$Comp
L C C30
U 1 1 5B0E2334
P 7250 1500
F 0 "C30" H 7275 1600 50  0000 L CNN
F 1 "100nF" H 7275 1400 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805_HandSoldering" H 7288 1350 50  0001 C CNN
F 3 "" H 7250 1500 50  0000 C CNN
	1    7250 1500
	1    0    0    -1  
$EndComp
Text GLabel 7600 1350 2    60   Input ~ 0
VCC3p3
$Comp
L C C9
U 1 1 5B0E2335
P 3950 1950
F 0 "C9" H 3975 2050 50  0000 L CNN
F 1 "100nF" H 3975 1850 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805_HandSoldering" H 3988 1800 50  0001 C CNN
F 3 "" H 3950 1950 50  0000 C CNN
	1    3950 1950
	1    0    0    -1  
$EndComp
$Comp
L C C13
U 1 1 5B0E2336
P 4250 1950
F 0 "C13" H 4275 2050 50  0000 L CNN
F 1 "100nF" H 4275 1850 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805_HandSoldering" H 4288 1800 50  0001 C CNN
F 3 "" H 4250 1950 50  0000 C CNN
	1    4250 1950
	1    0    0    -1  
$EndComp
Text GLabel 4700 1900 2    60   Input ~ 0
VCC2p5
$Comp
L C C10
U 1 1 5B0E2337
P 3950 2500
F 0 "C10" H 3975 2600 50  0000 L CNN
F 1 "100nF" H 3975 2400 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805_HandSoldering" H 3988 2350 50  0001 C CNN
F 3 "" H 3950 2500 50  0000 C CNN
	1    3950 2500
	1    0    0    -1  
$EndComp
$Comp
L C C14
U 1 1 5B0E2338
P 4250 2500
F 0 "C14" H 4275 2600 50  0000 L CNN
F 1 "100nF" H 4275 2400 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805_HandSoldering" H 4288 2350 50  0001 C CNN
F 3 "" H 4250 2500 50  0000 C CNN
	1    4250 2500
	1    0    0    -1  
$EndComp
Text GLabel 4650 2350 2    60   Input ~ 0
VCC1p2
Text GLabel 1250 4500 0    60   Input ~ 0
VCC
$Comp
L CP C3
U 1 1 5B0E233A
P 1400 6500
F 0 "C3" H 1425 6600 50  0000 L CNN
F 1 "10uF" H 1425 6400 50  0000 L CNN
F 2 "SMD_Packages:SMD-1206_Pol" H 1438 6350 50  0001 C CNN
F 3 "" H 1400 6500 50  0000 C CNN
	1    1400 6500
	1    0    0    -1  
$EndComp
Text GLabel 3300 3000 2    60   Input ~ 0
VCC3p3
$Comp
L GND #PWR04
U 1 1 5B0E8839
P 4650 2650
F 0 "#PWR04" H 4650 2400 50  0001 C CNN
F 1 "GND" H 4650 2500 50  0000 C CNN
F 2 "" H 4650 2650 50  0000 C CNN
F 3 "" H 4650 2650 50  0000 C CNN
	1    4650 2650
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR05
U 1 1 5B0E8A37
P 4700 2100
F 0 "#PWR05" H 4700 1850 50  0001 C CNN
F 1 "GND" H 4700 1950 50  0000 C CNN
F 2 "" H 4700 2100 50  0000 C CNN
F 3 "" H 4700 2100 50  0000 C CNN
	1    4700 2100
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR06
U 1 1 5B0E8AD6
P 7600 1650
F 0 "#PWR06" H 7600 1400 50  0001 C CNN
F 1 "GND" H 7600 1500 50  0000 C CNN
F 2 "" H 7600 1650 50  0000 C CNN
F 3 "" H 7600 1650 50  0000 C CNN
	1    7600 1650
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR07
U 1 1 5B0E8BFA
P 6450 1100
F 0 "#PWR07" H 6450 850 50  0001 C CNN
F 1 "GND" H 6450 950 50  0000 C CNN
F 2 "" H 6450 1100 50  0000 C CNN
F 3 "" H 6450 1100 50  0000 C CNN
	1    6450 1100
	1    0    0    -1  
$EndComp
Wire Wire Line
	950  1550 1600 1550
Wire Wire Line
	1600 1050 1600 2450
Connection ~ 1600 1150
Connection ~ 1600 1250
Connection ~ 1600 1350
Connection ~ 1600 1450
Connection ~ 1600 1550
Connection ~ 1600 1750
Connection ~ 1600 1050
Connection ~ 1600 1850
Connection ~ 1600 1950
Connection ~ 1600 2050
Connection ~ 1600 2150
Connection ~ 1600 2250
Connection ~ 1600 2350
Wire Wire Line
	3300 1350 2750 1350
Wire Wire Line
	2750 1050 2750 1750
Connection ~ 2750 1350
Connection ~ 2750 1050
Connection ~ 2750 1150
Connection ~ 2750 1250
Connection ~ 2750 1450
Connection ~ 2750 1550
Connection ~ 2750 1650
Connection ~ 2750 1750
Wire Wire Line
	1150 1550 1150 3500
Wire Wire Line
	1150 2800 1600 2800
Connection ~ 1150 1550
Wire Wire Line
	1150 3500 1600 3500
Connection ~ 1150 2800
Connection ~ 1600 2450
Wire Wire Line
	950  3600 1600 3600
Wire Wire Line
	1600 2900 1300 2900
Wire Wire Line
	1300 2900 1300 3600
Connection ~ 1300 3600
Wire Wire Line
	950  2700 1600 2700
Wire Wire Line
	1450 2700 1450 3400
Wire Wire Line
	1450 3400 1600 3400
Connection ~ 1450 2700
Wire Wire Line
	2750 3000 3300 3000
Wire Wire Line
	2750 2500 2750 3600
Connection ~ 2750 3000
Connection ~ 2750 2900
Connection ~ 2750 2800
Connection ~ 2750 2700
Connection ~ 2750 2600
Connection ~ 2750 2500
Connection ~ 2750 3100
Connection ~ 2750 3200
Connection ~ 2750 3300
Connection ~ 2750 3400
Connection ~ 2750 3500
Connection ~ 2750 3600
Wire Wire Line
	1400 5750 2200 5750
Connection ~ 1800 5750
Wire Wire Line
	2400 6350 2100 6350
Connection ~ 2200 6350
Connection ~ 1800 6650
Wire Wire Line
	1200 6350 1500 6350
Wire Wire Line
	1850 6600 1800 6600
Wire Wire Line
	1800 6600 1800 6650
Wire Wire Line
	1400 6650 2200 6650
Wire Wire Line
	1250 4500 1500 4500
Wire Wire Line
	2400 4500 2100 4500
Connection ~ 2200 4500
Wire Wire Line
	1400 4800 2200 4800
Connection ~ 1800 4800
Wire Wire Line
	3950 800  6450 800 
Connection ~ 4250 800 
Connection ~ 4550 800 
Connection ~ 4850 800 
Connection ~ 5150 800 
Connection ~ 5450 800 
Connection ~ 5750 800 
Wire Wire Line
	3950 1100 6450 1100
Connection ~ 4250 1100
Connection ~ 4550 1100
Connection ~ 4850 1100
Connection ~ 5150 1100
Connection ~ 5450 1100
Connection ~ 5750 1100
Connection ~ 6050 800 
Connection ~ 6050 1100
Connection ~ 4250 1350
Connection ~ 4550 1350
Connection ~ 4850 1350
Connection ~ 5150 1350
Connection ~ 5450 1350
Connection ~ 5750 1350
Connection ~ 4250 1650
Connection ~ 4550 1650
Connection ~ 4850 1650
Connection ~ 5150 1650
Connection ~ 5450 1650
Connection ~ 5750 1650
Connection ~ 6050 1350
Connection ~ 6050 1650
Connection ~ 6350 1350
Connection ~ 6650 1350
Connection ~ 6950 1350
Connection ~ 6350 1650
Connection ~ 6650 1650
Connection ~ 6950 1650
Connection ~ 7250 1350
Connection ~ 7250 1650
Wire Wire Line
	3950 1350 7600 1350
Wire Wire Line
	3950 1650 7600 1650
Connection ~ 4250 1800
Connection ~ 4250 2100
Wire Wire Line
	3950 1800 4700 1800
Wire Wire Line
	3950 2100 4700 2100
Connection ~ 4250 2350
Connection ~ 4250 2650
Wire Wire Line
	3950 2350 4650 2350
Wire Wire Line
	3950 2650 4650 2650
Connection ~ 1400 4500
Wire Wire Line
	1100 5350 1500 5350
Wire Wire Line
	1400 5450 1400 5350
Connection ~ 1400 5350
Wire Wire Line
	2100 5350 2350 5350
Wire Wire Line
	2200 5450 2200 5350
Connection ~ 2200 5350
Wire Wire Line
	4700 1800 4700 1900
$Comp
L GND #PWR08
U 1 1 5B0EB02A
P 950 1550
F 0 "#PWR08" H 950 1300 50  0001 C CNN
F 1 "GND" H 950 1400 50  0000 C CNN
F 2 "" H 950 1550 50  0000 C CNN
F 3 "" H 950 1550 50  0000 C CNN
	1    950  1550
	1    0    0    -1  
$EndComp
Wire Wire Line
	3750 4800 3750 5100
Wire Wire Line
	3750 5100 4150 5100
$Comp
L GND #PWR09
U 1 1 5B14C6B4
P 3750 5100
F 0 "#PWR09" H 3750 4850 50  0001 C CNN
F 1 "GND" H 3750 4950 50  0000 C CNN
F 2 "" H 3750 5100 50  0000 C CNN
F 3 "" H 3750 5100 50  0000 C CNN
	1    3750 5100
	1    0    0    -1  
$EndComp
$Comp
L AP111733 U2
U 1 1 5B14CC28
P 1800 5350
F 0 "U2" H 1900 5100 50  0000 C CNN
F 1 "AMS1117-3.3" H 1800 5600 50  0000 C CNN
F 2 "TO_SOT_Packages_SMD:SOT-223" H 1800 5000 50  0001 C CNN
F 3 "" H 1900 5100 50  0000 C CNN
	1    1800 5350
	1    0    0    -1  
$EndComp
Wire Wire Line
	1800 5650 1800 5750
Text GLabel 3550 4500 0    60   Input ~ 0
VCC
Wire Wire Line
	3550 4500 3750 4500
$Comp
L USB_B P2
U 1 1 5B1503ED
P 4050 4700
F 0 "P2" H 4250 4500 50  0000 C CNN
F 1 "USB_A" H 4000 4900 50  0000 C CNN
F 2 "Connectors:USB_A" V 4000 4600 50  0001 C CNN
F 3 "" V 4000 4600 50  0000 C CNN
	1    4050 4700
	0    1    1    0   
$EndComp
Wire Wire Line
	4150 5100 4150 5000
Connection ~ 1600 1650
Connection ~ 1400 6350
$Comp
L USB_A P5
U 1 1 5B1CB75A
P 4000 5750
F 0 "P5" H 4200 5550 50  0000 C CNN
F 1 "USB_A" H 3950 5950 50  0000 C CNN
F 2 "Connectors:USB_A" V 3950 5650 50  0001 C CNN
F 3 "" V 3950 5650 50  0000 C CNN
	1    4000 5750
	0    1    1    0   
$EndComp
Text GLabel 3550 5550 0    60   Input ~ 0
VCC
Wire Wire Line
	3550 5550 3700 5550
Wire Wire Line
	3700 5850 3700 6200
Wire Wire Line
	3700 6050 4100 6050
Connection ~ 3700 6050
$Comp
L GND #PWR010
U 1 1 5B1CBCA1
P 3700 6200
F 0 "#PWR010" H 3700 5950 50  0001 C CNN
F 1 "GND" H 3700 6050 50  0000 C CNN
F 2 "" H 3700 6200 50  0000 C CNN
F 3 "" H 3700 6200 50  0000 C CNN
	1    3700 6200
	1    0    0    -1  
$EndComp
Connection ~ 3750 5100
NoConn ~ 3750 4600
NoConn ~ 3750 4700
NoConn ~ 3700 5650
NoConn ~ 3700 5750
$EndSCHEMATC
