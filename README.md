## Introduction

This is a WIP project to implement a light replacement of a CPU inside a printer with ESP-32. Current state: "on hold".

The original goal was to print images in raw quality, pixel perfect, e.g. without additional transformation from an APP but there were caveats so I am developing a replacement of a CPU that will be focused on quality instead of speed.

- [Introduction](#introduction)
- [Other projects](#other-projects)
- [Developing a Bluetooth App](#developing-a-bluetooth-app)
  - [Swift RFCOMM](#swift-rfcomm)
  - [Bluetooth packets observed by logic analyzer using pins on the PCB](#bluetooth-packets-observed-by-logic-analyzer-using-pins-on-the-pcb)
  - [Mac OS Swift RFCOMM Bluetooth packets compared to Android](#mac-os-swift-rfcomm-bluetooth-packets-compared-to-android)
  - [Bluetooth packets from iOS, GATT Bluetooth protocol](#bluetooth-packets-from-ios--gatt-bluetooth-protocol)
  - [Printing from Mac OS Web Browser using GATT Bluetooth protocol observed from iOS Bluetooth log](#printing-from-mac-os-web-browser-using-gatt-bluetooth-protocol-observed-from-ios-bluetooth-log)
  - [Printing from MacOS Python script using GATT protocol](#printing-from-macos-python-script-using-gatt-protocol)
  - [Issue is specific to MacBook](#issue-is-specific-to-macbook)
  - [Trying native iPad app on ARM Macbook](#trying-native-ipad-app-on-arm-macbook)
- [Connecting to the printer using USB-UART dongle directly, without a Bluetooth.](#connecting-to-the-printer-using-usb-uart-dongle-directly--without-a-bluetooth)
- [The Issue](#the-issue)
- [Improving printing technology by replacing CPU with an ESP-32](#improving-printing-technology-by-replacing-cpu-with-an-esp-32)
  - [Observing the Printer Head](#observing-the-printer-head)
  - [Searching through the web for an algorithm](#searching-through-the-web-for-an-algorithm)
  - [Recording data from CPU to Printer Head, investigation, confusion and reverse-engineering the protocol](#recording-data-from-cpu-to-printer-head--investigation--confusion-and-reverse-engineering-the-protocol)
  - [Stepper motor gear ratio, steps per pixel](#stepper-motor-gear-ratio--steps-per-pixel)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>

## Other projects

Some projects on GitHub are connecting to the printer using RFCOMM Bluetooth protocol:
https://github.com/eliasweingaertner/peripage-A6-bluetooth/tree/master
https://github.com/bitrate16/peripage-python/tree/main

However on MacBook with ARM chip, PyBluez, which is used in that project, is not installing.

Also, there is an issue related to printing from a PC which I reproduced in further investigations.
https://github.com/bitrate16/peripage-python/issues/17

## Developing a Bluetooth App

### Swift RFCOMM

I have tried to develop a MacOS app without PyBluez, but the only thing working that I have found is a Swift RFCOMM example https://github.com/garvincasimir/coco-bluetooth-rfcomm-swift/blob/master/Cocoa%20Bluetooth%20RFCOMM%20Swift/AppDelegate.swift

So I have tried to connect using Swift, It was successful printing. However, there were blank lines as it was described in this issue: https://github.com/bitrate16/peripage-python/issues/17

### Bluetooth packets observed by logic analyzer using pins on the PCB

After looking at the internals of PeriPage A6, [I have found two UARTs, one is between the CPU and Bluetooth module (transfers the data in the same form as from the projects above) and the second is from Bluetooth to nowhere (some a little bit readable debug Bluetooth data)](./info/pcb/3%20UART%20pins%20and%20GND.jpg) [here is a [log](./info/saleae/original%20chip/connection%20+%20printing%20android.sal)]

### Mac OS Swift RFCOMM Bluetooth packets compared to Android

After inspecting the Bluetooth-CPU UART using Logic Analyzer, I have found that if I am using Swift with RFCOMM - there is super huge latency between Bluetooth packets that are coming into CPU - something like 100ms between each 2 packets [[log](<./info/saleae/original%20chip/printing%20from%20macbook%20using%20swift+rfcomm%20(BT%20UART%20LOG).sal>)], whereas if I am using iOS app it is 0-3ms per package [[log](./info/saleae/original%20chip/connection%20+%20printing%20iphone%20high%20concentration.sal)] and if I am using Android app it is 20ms per 4 packages (28 packets per 500ms) [[log](./info/saleae/original%20chip/connection%20+%20printing%20android.sal)]

### Bluetooth packets from iOS, GATT Bluetooth protocol

I have tried to inspect the Bluetooth logs from Android [[log](./info/bt/wireshark/android%20redmi%204x.log)] and iOS [[log](./info/bt/wireshark/connect%20print%20ios.pklg)] and found that iOS is not using RFCOMM protocol. Instead, it uses the GATT protocol. So it is writing attributes to a printer and not using a printer like a Serial Port.

### Printing from Mac OS Web Browser using GATT Bluetooth protocol observed from iOS Bluetooth log

I have successfully connected and printed from the browser using GATT. The latency between packets (inspected using a logic analyzer) was about 20 ms.
After inspecting the logs further to see some difference between iOS 3ms and MacOS 20ms - It looks like there is no difference. Looks like there is also a logic to send two packets into the printer and do not send packets until there is a response "0102" from attribute 0xff03 [[screenshot](./info/readme%20images/Screenshot%202024-08-11%20at%2023.29.02.png)]. After implementing such logic I saw no improvement in latency from MacOS.

### Printing from MacOS Python script using GATT protocol

So I have tried to improve the connection to 3ms by using other GATT tools and found a "bleak" Python package. It is in active development and it is supported on ARM MacBook.
I tried to send Bluetooth packets from bleak from MacOS [[project](./info/bt/connecting%20using%20bleak%20Python%20GATT%20MacOS%20to%20test%20bluetooth%20latency/bleak/)] and found no improvement over 20ms

### Issue is specific to MacBook

That looked very strange to me because the packets were exactly the same as from the iPhone, so I tried to run bleak on a Windows machine, and voila - 3-10ms latency. So it looks like the appearance of a blank line is very dependent on Bluetooth Hardware.

### Trying native iPad app on ARM Macbook

Also, after that, I tried to use the original PeriPage app on MacOS (ARM MacOS supports apps for iPad so I could download PeriPage for iPad and run on MacOS). There were blank lines and the latency was like before - 20ms.

## Connecting to the printer using USB-UART dongle directly, without a Bluetooth.

The results were not acceptable to me so I tried to directly connect to the printer using a USB-UART dongle [[project](./info/direct%20connect%20usb-uart%20to%20cpu%20-%20nodejs/)]. It was awesome, the printer worked like a charm. No blank lines. The only issue is that Bluetooth UART lines have to be cut up to disconnect the Bluetooth chip from the CPU. Bluetooth chip has a strong pull-up on these lines which disallows data transmission from USB-UART.

Also, after startup, the CPU asks the Bluetooth `AT+BT=1\r\n` and expects the Bluetooth to respond `\r\nOK\r\n`. It sends the enable message until it hears an OK response from Bluetooth, so it has to be sent from USB-UART (There is no specific time when to send. Just before printing). Also, I have accidentally found, after sending OK multiple times, that this OK will be printed on a page, so send OK only one time. So the printer also accepts ASCII chars on the UART and tries to print that.

## The Issue

I have found that I am getting rare more black or more white lines. It looks like at the moments when the printer switches a motor speed or for some other reason, the line may be printed vertically misaligned. [img](./info/readme%20images/Screenshot%202024-08-09%20at%2013.51.25.png) [img2](./info/readme%20images/Screenshot%202024-08-09%20at%2013.51.25%20copy.png) [img3](./info/readme%20images/Screenshot%202024-08-12%20at%2000.50.45.png) (please do not look at the vertical `|` artifacts - these are artifacts with my scanner)

## Improving printing technology by replacing CPU with an ESP-32

### Observing the Printer Head

There was an unknown printing head with cable "A6-ROHM300-3.7", looks like A6 is the printer's name, ROHM is something unknown, BTW there is a company ROHM Semiconductor, and 3.7 may be a print voltage. I am not sure if the head has been designed specifically for this printer completely or if it is just a custom flex cable. On the head, there is a KTH0697-1, 94V-0, and HY-280 labels.
UPD: it may be [ROHM KR3002-B06N1BA](https://www.rohm.com/products/printheads/mobile-printers/kr3002-b06n1ba-product) head.

### Searching through the web for an algorithm

So I have tried to record data transmission from the CPU into the printing head and was disappointed: I could not find anything (datasheet) related to this head on the internet. Printing heads is a new thing to me. I have found an algorithm on [some website](https://habr.com/ru/companies/timeweb/articles/724308/) but the head and connections were different.

### Recording data from CPU to Printer Head, investigation, confusion and reverse-engineering the protocol

Also, I have tried to inspect the data from the CPU to the printing head with a logic analyzer and found that on the black image, the data sent is not a black line, but only some black pixels [[log](<./info/saleae/original%20chip/black%20256-height%20max(2)-concentration.sal>)].
After some investigation, the only logical solution to me is that the printer is not turning all 576 black pixels for some unknown reason. Also after doing some statistics, I have found that always no more than 64 pixels were turned simultaneously.

After further investigation and finding a [datasheet to a similar printing head](./datasheet/LTP02-245-13_TR_E_U00131701401.pdf), it became clear that it is recommended to not turn on more than ~12% of pixels simultaneously.

The printer is printing with the heating turned on 99.8% of the printing time (it is turned off 0.2% of the time just to write new pixels into the printing head and then turn on the heating) and the motor is turned permanently on. "Image rows" are split into "printing lines" with no more than 64 black pixels. When an "image row" consists of more black pixels, the motor slows down because the printer has to draw multiple printing lines to draw a single "image row".

Each "image row" is printed at least two times (two "printing lines"). It is printed two times when black pixels in a row are <=64 [[example](./info/printing%20head%20dump%20renderer/dumps/g/canvas.png)], and "four times with 64 pixels" when an "image row" has between 65 and 128 black pixels, and so on [example](./info/printing%20head%20dump%20renderer/dumps/cat2/canvas.png) of printing [this image](<./info/sample%20image/dither_it_Asana3808_Dashboard_Standard%20(1).png>) using USB-UART (pixel perfect)

There is a Node.Js script that converts Logic Analyzer Log into an image of what pixels were rendered at the same time [[link](./info/printing%20head%20dump%20renderer/e.js)].

### Stepper motor gear ratio, steps per pixel

Looks like the printer has a gear ratio `GearRatio = ((24 / 12) * (28 / 13) * (40 / 12) * (21 / 12)) ≈ 25.1282051282` [[confirmation](./info/motor/2024-08-12%2011.28.12.jpg)].

So one degree of stepper motor is equal to `OneDegreeOfStepperMotorInDegreesOfPaperFeederCoefficient = 1 / ((24 / 12) * (28 / 13) * (40 / 12) * (21 / 12)) ≈ 0.03979591836` degrees of paper feeder.

It is experimentally investigated that the stepper motor has to do 40 steps to do a 360-degree rotation, so one step is `OneStepOfStepperMotorInDegrees = 360 / 40 = 9` degrees.

The paper feeder has a diameter of 6.70mm and the middle of feeder slides through a caliper freely at 6.70mm [[Caliper](./info/motor/photo_2024-08-12%2011.50.05.jpeg)], however, it is quite soft, so under pressure it may become 6.50mm or so. The circumference is `pi * diameter` = `FeederCircumference6.7mm = (6.7 * pi) ≈ 21.0486707791` millimeters. The 6.5mm is `FeederCircumference6.5mm = (6.5 * pi) ≈ 20.4203522483` millimeters.

One degree of turning the paper feeder is `OneDegreeFeederCircumference6.7mm = (FeederCircumference6.7mm / 360) ≈ 0.05846852994`, `OneDegreeFeederCircumference6.5mm = (FeederCircumference6.5mm / 360) ≈ 0.05672320068` millimeters.

So, one step of stepper motor is equal to `OneStepOfStepperMotorInDegreesOfFeeder = OneStepOfStepperMotorInDegrees * OneDegreeOfStepperMotorInDegreesOfPaperFeederCoefficient ≈ 0.3581632653` degrees of turn of paper feeder, which is equal to `OneStepOfStepperMotorInMillimetersOfPaper6.7mm = OneStepOfStepperMotorInDegreesOfFeeder * OneDegreeFeederCircumference6.7mm ≈ 0.0209412796` millimeters or if we assume that feeder has 6.5mm diameter, `OneStepOfStepperMotorInMillimetersOfPaper6.5mm = OneStepOfStepperMotorInDegreesOfFeeder * OneDegreeFeederCircumference6.5mm ≈ 0.02031616677` millimeters.

This means that one millimeter is equal to `StepsOfStepperMotor6.7mmInOneMillimeter = 1 / OneStepOfStepperMotorInMillimetersOfPaper6.7mm ≈ 47.7525738171` steps or if assume 6.5mm feeder diameter: `StepsOfStepperMotor6.5mmInOneMillimeter = 1 / OneStepOfStepperMotorInMillimetersOfPaper6.5mm ≈ 49.2218837807` steps

The width of the printer head is 48mm so in one millimeter there are `PixelsInOneMM = 576 / 48 = 12` pixels. Pixels have to be square so the height of the printed pixel should be the same as the width of the printed pixel, so we can just calculate the number of pixels fitting in the 1mm width and assume that it is the same number as pixels fitting in the 1mm height.

So to draw one pixel, the motor has to do `StepsOfStepperMotor6.7mmToDrawOnePixel = StepsOfStepperMotor6.7mmInOneMillimeter / PixelsInOneMM ≈ 3.97938115142` steps or if assume 6.5mm feeder diameter: `StepsOfStepperMotor6.5mmToDrawOnePixel = StepsOfStepperMotor6.5mmInOneMillimeter / PixelsInOneMM ≈ 4.10182364839` (`1 / (((360 / 40) * (1 / ((24 / 12) * (28 / 13) * (40 / 12) * (21 / 12)))) * ((6.7 * pi) / 360)) / (576 / 48)`) steps which is very close to 4 in both cases.

So the stepper has to do 4 steps to move from line to line, which is the same as the number of steps the original software from PeriPage does to print a line [[img](./info/readme%20images/Screenshot%202024-08-12%20at%2013.45.39.png)] [[log](./info/saleae/original%20chip/motor.sal)]

## Example improvements that maybe can be done

Turning on specific pixels at the 75% or 50% or 25% or 12% (...) of heating time to have more than 1 bit of color.

## Stop of development

There are some WIP branches with different approaches.

### There is a strict limit of improvements that can be done, due to issues:

- If "motor is turned slowly" and "the printed area in a row is large" and "the power (contrast) is high", the paper is sticking to the printing head. - only 4th motor step actually moves the paper.
- It is complicated to handle/calculate/measure heating and cooling impact on contrast of specific pixels.
- No more than 64 pixels should be turned on at the same time
- It is complicated to create a perfect pattern of changing 64 pixels to have same heating effect on all pixels with regard to the cooling effect.
- It is complicated to calculate perfect timings for turning the motor / enabling the heating / cooling / drawing the subline (on one step of motor (1 line is 4 sublines))
- When less than 64 (or typical amount) pixels are turned on, the heating effect changes due to changes of resistance of the printing head.
- There is no feasible way to increase "available time during printing" for time consuming improvements by fixing the "motor is turned slowly" issue by increasing thermal head voltage and speeding up the motor because a DC/DC converter IN:3.0-4.2v OUT:5v with support of 2-3A on the output is a somewhat big device compared to a size of a printer. (Such DC/DC converter can not be fitted inside a printer easily)
