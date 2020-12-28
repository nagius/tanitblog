---
title: ESP-8266 power issue with ME6206 regulator
date: 20200822
tags:
 - ESP8266
 - Electronics
---

The other day I was doing some tests with an ESP-8266 powered from a battery via a ME6206 LDO voltage regulator and a TPS3839 voltage detector on the enable pin.
A classic setup, copied from the datasheets.

Every components worked fine in the test bench, everything worked fine together from a 5V power supply.
But once powered from the Li-ion cell, the voltage detector started to oscillate and resetted the ESP multiple time a second !

That was very strange as in both cases, with the 5V supply or the battery, the output voltage of the regulator, as the input of the voltage detector, was good at 3.3V.
The ESP is drawing just below 70mA, that's way below the maximum rating of 300mA for the ME6206. All the recommended capacitors where in place..

So what is this black magic ?

Like often in these cases, the only way to find out is a scope. Luckly I had a SDO on hands.

<img src="/blog/img/voltage-dip-no-cap.jpg" width="450" alt="Voltage drop without capacitor">
<div align="center">*Voltage drop without capacitor*</div>

And here is the culprit. A big drop of voltage to 2.9V during 1ms. That's a 400mV drop, quite huge !
Obviously, that drop was triggering the voltage detector threshold, set at 3.08V.

After investigation, this is coming from the power consumption profile of the ESP. The average is around 60mA but there is spikes at 220mA during 1ms regulary. I could'nt get the exact frequency with my tools but it matched the voltage drop, something around 1OHz maybe.

<img src="/blog/img/current-spike-no-capa.jpg" width="450" alt="Current spike without capacitor">
<div align="center">*Current spike without capacitor*</div>

220mA is below the maximum rating of the ME6206 so that's not the issue. But the surge in current induce an increase of voltage dropout. Which explains why there is a voltage drop when the battery is around 3.5v and not when the voltage is higher.
That behavior  matches the datasheet (when you know what you're looking for) : 400mV dropout voltage at 200mA...

The solution would be to add a 2200µF capacitor to smooth out this dip. Smaller capacitor are not enough.
A 220µF started to round a bit the edges of the square dent in the voltage but nothing useful.
Even a big 1000µF was not enough to smooth out the voltage completely. A small dip remains and triggered the voltage detector from time to time.

<img src="/blog/img/voltage-dip-1000uF.jpg" width="450" alt="Voltage drop with 1000µF capacitor">
<div align="center">*Voltage drop with 1000µF capacitor*</div>

As a side effect of this added capacitor, the voltage rise lowly on startup and the ESP does'nt work without a reset. A voltage detector on the enable pin is mandatory.
This solution is working fine but starts to oscillate when the battery reaches 3.3V and lead to a runtime of only 33h instead of 41 without the capacitor.

The real solution is to put the voltage detector BEFORE the voltage regulator. It's not super accurate as the voltage drop on the regulator is ignored with this setup, but it gives a stable result.

Side note, as I has the scope plugged, I had a look at the voltage of the ESP. quite noisy.
Look like a 220µF capacitor is a minimum to filter out the smalls spike but it's not enough for this big one.

<img src="/blog/img/flat-voltage-no-capa.jpg" width="450" alt="Output voltage without capacitor">
<div align="center">*Output voltage without capacitor*</div>
