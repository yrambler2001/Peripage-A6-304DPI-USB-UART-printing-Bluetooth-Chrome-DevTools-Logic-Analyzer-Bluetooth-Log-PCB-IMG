Original goal was to print image in raw quality, pixel perfect, e.g. without additional transformation from an APP.

There are some projects on GitHub that are connecting to the printer using RFCOMM Bluetooth protocol:
https://github.com/eliasweingaertner/peripage-A6-bluetooth/tree/master
https://github.com/bitrate16/peripage-python/tree/main

However on MacBook with ARM chip, PyBluez is not installing.

Also there is an issue related to printing from PC which I had reproduced in further investigations.
https://github.com/bitrate16/peripage-python/issues/17

---

I have tried to develop some MacOS app without PyBluez, but the only thing working that I have found is a Swift RFCOMM example https://github.com/garvincasimir/coco-bluetooth-rfcomm-swift/blob/master/Cocoa%20Bluetooth%20RFCOMM%20Swift/AppDelegate.swift

So I have tried to connect using Swift, It was successful printing. however there were blank lines as it was described in this issue: https://github.com/bitrate16/peripage-python/issues/17

After looking at the internals of PeriPage A6, [I have found two UARTs, one is between CPU and Bluetooth module (transfers the data in the same form like from the projects above) and second is from Bluetooth to nowhere (some a little bit readable debug bluetooth data)](./info/pcb/3%20UART%20pins%20and%20GND.jpg) here is a [log](./info/saleae/original%20chip/connection%20+%20printing%20android.sal)

After inspecting the Bluetooth-CPU UART using Logic Analyzer, I have found that if I am using Swift with RFCOMM - there is super huge latency between bluetooth packets that are coming into CPU - something like 100ms between each 2 packets [log](<./info/saleae/original%20chip/printing%20from%20macbook%20using%20swift+rfcomm%20(BT%20UART%20LOG).sal>), whereas if I am using iOS app it is 0-3ms per package [log](./info/saleae/original%20chip/connection%20+%20printing%20iphone%20high%20concentration.sal) and if I am using Android app it is 20ms per 4 packages (28 packets per 500ms) [log](./info/saleae/original%20chip/connection%20+%20printing%20android.sal)

I have tried to inspect the Bluetooth logs from Android [log](./info/bt/wireshark/android%20redmi%204x.log) and iOS [log](./info/bt/wireshark/connect%20print%20ios.pklg) and found that iOS is not using RFCOMM protocol. Instead, it uses GATT protocol. So it is writing attributes to a printer and not using a printer like a Serial Port.

I have managed to connect and print from browser using GATT successfully. The latency between packets (inspected using logic analyzer) was like 20ms.
After inspecting the logs further to be able to see some difference between iOS 3ms and MacOS 20ms - It looks like there is no difference. Looks like there is also a logic to send two packets into printer and do not send packets until there is a response "0102" from attribute 0xff03 [screenshot](./info/readme%20images/Screenshot%202024-08-11%20at%2023.29.02.png). After implementing such logic I saw no improvement in latency from MacOS.

So I have tried to improve the connection to 3ms by using other GATT tools and found bleak python package. It is in active development and it is supported on ARM MacBook.
I tried to send Bluetooth packets from bleak from MacOS [project](./info/bt/connecting%20using%20bleak%20Python%20GATT%20MacOS%20to%20test%20bluetooth%20latency/bleak/) and found no improvement over 20ms

That looked very strange to me because the packets were exact the same like from iPhone, so I tried to run bleak on a Windows machine and voila - 3-10ms latency. So it looks like the lines appearance is very dependent on a Bluetooth Hardware.

Also, after that, I have tried to use original PeriPage app on MacOS (ARM MacOS supports apps for iPad so I could download PeriPage for iPad and run on MacOS). There were blank lines and the latency was like before - 20ms.

---

Results were not acceptable for me so I have tried to directly connect to the printer using USB-UART dongle [project](./info/direct%20connect%20usb-uart%20to%20cpu%20-%20nodejs/). It was awesome, the printer worked like a charm. No blank lines. The only issue is that Bluetooth UART lines have to be cut up to disconnect bluetooth chip from the CPU. Bluetooth chip has a strong pull-up on these lines which disallows data transmission from USB-UART.

Also, after startup, CPU is asking the Bluetooth `AT+BT=1\r\n` and expects the Bluetooth to respond `\r\nOK\r\n`. It sends the enable message until it hear a OK response from Bluetooth, so it has to be sent from USB-UART (There is no specific time when to send. Just before printing). Also, I have accidentally found, after sending OK multiple times, that this OK will be printed on a page, so send OK only one time. So the printer also accepts ASCII chars on the UART and tries to print that.

---

I have found that I am getting rare more black or more white lines. It looks like at the moments when printer switches a motor speed or for some other reason, the line may be printed vertically misaligned. [img](./info/readme%20images/Screenshot%202024-08-09%20at%2013.51.25.png) [img2](./info/readme%20images/Screenshot%202024-08-09%20at%2013.51.25%20copy.png) [img3](./info/readme%20images/Screenshot%202024-08-12%20at%2000.50.45.png) (please do not look at the vertical `|` artifacts - these are artifacts with my scanner)

There was unknown printing head with cable "A6-ROHM300-3.7", looks like A6 is printer name, ROHM is something unknown, BTW there is a company ROHM Semiconductor, and 3.7 may be a print voltage. I am not sure if the head has been designed specifically for this printer completely or it is just a custom flex cable. On the head there is a KTH0697-1, 94V-0, HY-280 labels.

So I have tried to record data transmission from CPU into printing head and was disappointed: I could not find anything (datasheet) related to this head on the internet. Printing heads is a new thing to me. I have found an algorithm on [some website](https://habr.com/ru/companies/timeweb/articles/724308/) but the head and connections were different.

Also I have tried to inspect the data from CPU to printing head with logic analyzer and found that on black image, the data sent is not black line, but only some black pixels. [log](<./info/saleae/original%20chip/black%20256-height%20max(2)-concentration.sal>)
After some investigation, the only logical solution to me is that printer is not turning all 576 black pixels for some unknown reason. Also after doing some statistics, I have found that always no more than 64 pixels were turned simultaneously.

After further investigation and finding a [datasheet to a similar printing head](./datasheet/LTP02-245-13_TR_E_U00131701401.pdf), it became clear that it is recommended to not turn on more than ~12% of pixels simultaneously.

Printer is printing with heating turned on 99.8% of the printing time (it is turned off 0.2% of the time just to write new pixels into printing head and then turn on the heating) and motor turned permanently on. "Image rows" are splitted into "printing lines" with no more than 64 black pixels. When an "image row" consists of more black pixels, the motor slows down because the printer has to draw multiple printing lines to draw single "image row".

Each "image row" is printed at least two times (two "printing lines"). It is printed two times when black pixels in a row is <=64 [example](./info/printing%20head%20dump%20renderer/dumps/g/canvas.png), and "four times with 64 pixels" when an "image row" has between 65 and 128 black pixels, and so on [example](./info/printing%20head%20dump%20renderer/dumps/cat2/canvas.png) of printing [this image](<./info/sample%20image/dither_it_Asana3808_Dashboard_Standard%20(1).png>) using USB-UART (pixel perfect)

There is a Node.Js script that converts Logic Analyzer Log into an image of what pixels were rendered at the same time [link](./info/printing%20head%20dump%20renderer/e.js).

---

This is a WIP project to implement a light replacement of a CPU inside a printer with ESP-32.