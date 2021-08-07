---
title: ESP and solar panel Part 2; the results
date: 20210805
tags:
 - ESP8266
 - Electronics
---

In the previous episode, we saw the setup to measure solar panel production with an ESP. Today we are going to see the results with the two different controlers.

# CN3791

The CN3791 needs a bit of tuning to setup the Maximum Power Point the controler will use. It can be adjusted with a variable resistor.
I found the best value to be 5.2V for my 6V solar panel.

The result is quite clean. The controller keep the panel voltage around 5.2V to get the maximum power. Once the panel hits the shades (just before 10am on the graphs), the power drop a lot but still produces a few mW at 5.2V.

<img src="/blog/img/esp/solar-power-CN3791.png" width="450" alt="CN3791 daily power production">
<div align="center">*CN3791 daily power production*</div>

<img src="/blog/img/esp/solar-voltage-CN3791.png" width="450" alt="CN3791 voltage with MPP tracking">
<div align="center">*CN3791 voltage with MPP tracking*</div>

The production peaks at 1.2W, which is way less than the expected 4W of the solar panel's datasheet.


# TP4056

With the TP4056, it's a bit more messy. There is no MPP tracking (and no tuning). It draws as much as it can pulling the voltage down to around 4V, with an average at 4.6V. As a result the energy produced is a bit more chaotic but it's still working.

<img src="/blog/img/esp/solar-power-TP4056.png" width="450" alt="TP4056 daily power production">
<div align="center">*TP4056 daily power production*</div>

<img src="/blog/img/esp/solar-voltage-TP4056.png" width="450" alt="TP4056 voltage without MPP tracking">
<div align="center">*TP4056 voltage without MPP tracking*</div>

The production peak is around the same.

# Conclusion

The TP4056 seems to be a little bit less efficient but the results are quite similar in both full sun and shades. A better setup would be required to measure the impact on the battery charges, as the voltage required to charge it will depend of its charge level (ie, 4V will not be enough is the battery is nearly full).

One thing to note though is the impact of the panel's temperature. As soon as the panel reached around 40°C, the harvested power dropped by half. With the temperature returning below 35°C, the prodution went back to normal. To note, the temperature sensor at the back of the panel it not in proper contact with it. Some thermal grease would be needed. The real temperature of the panel might be much higher.

<img src="/blog/img/esp/solar-temperature.png" width="450" alt="Temperature at the back of the panel">
<div align="center">*Temperature at the back of the panel*</div>

<img src="/blog/img/esp/solar-current.png" width="450" alt="Current curve when heating">
<div align="center">*Current curve when heating*</div>

But the main take away is: To get good solar power, you need good sun.

