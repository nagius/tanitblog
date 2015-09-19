---
title: My custom ortholinear keyboard
date: 20150918
tags:
 - Keyboards
---
Recently, I bought two nice keyboards: 

 * a DasKeyboard Ultimate, one of the best mechanical with a regular staggered layout:

<br>![DasKeyboard](/blog/img/daskeyboard-4-ultimate.jpg)

 * and a TypeMatrix, the most famous ortholinear keyboard:

<br><img src="/blog/img/typematrix-2030.jpg" width="450" alt="TypeMatrix">

Both of them have really good point, but none of them is perfect. The TypeMatrix has a really good modern layout but the mechanical feeling of the DasKeyboard is better.

After few weeks with these two keyboards, I came up with an idea: why not mixing them and make the best keyboard ?

So I made this :

<br><img src="/pub/DasMatrix/DasMatrix_v03.png" width="450" alt="DasMatrix">

No, seriously, this is not only a computer graphics, I really built it :

<br><img src="/pub/DasMatrix/final_result.jpg" width="450" alt="DasMatrix">

Of course, it hasn't been so simple. Luckily, I found a great community of hackers and makers on [Geekhack](https://geekhack.org), which was really helpful to learn how to make a keyboard. 
There is a lot of talented dude building awesome keyboards out there ! And they not only build keyboards, they also make software to do it ! 

The first tool, [Keyboard Layout Editor](http://www.keyboard-layout-editor.com/), is really handy to quickly design custom layout. Then, the second tool, [swill's plate building tool](http://builder.swillkb.com/) use the previously defined layout and generate the CAD file you need in order to make the plate. It seems so easy when the good guys are here.

The main concept of this mod is to replace the inner plate and the PCB, to allow a custom layout, but without modifying anything else. I wanted to keep the original controller and the case.

At the end, this is mainly a reverse engineering task on the DasKeyboard internals.

Design
======

To do the job, I only used open source softwares : LibreCAD for the plate and KiCad for the PCB.
The learning curve of these tools is not so easy, but there is plenty of tutorials and blogs everywhere, so it's just a matter of time and patience...

One of the numerous difficulties was to perfectly sync the position of the switches between the plate and the PCB. To do that, I find a way to import the DXF file into KiCad and use it as the edge cut layout: [dxf2svg2kicad](http://mondalaci.github.io/dxf2svg2kicad/). Thanks to this guy !

For the plate, it's a precision reverse engineering work, as I had to redo the same edge cut and mounting holes with a precision below 0.05mm. I spent hours playing with my sliding caliper. Here is the comparison between my plate and the original one:

<br><img src="/pub/DasMatrix/plates.jpg" width="450">

For the PCB, nothing really complicated, this is just wiring switches and diodes. But the original PCB from the DasKeyboard is really twisted, it took me a long time to follow each tracks and rebuild the wired matrix.
I added a FPC connector to be able to connect to the original controller.

<br><img src="/pub/DasMatrix/PCBs.jpg" width="450">

Manufacturer
============

Once the design done, the DXF and Gerber files ready, I had to find a way to make these objects real, I mean, find some companies to cut and print it.

As far as I know, there is only one compagny doing water jet cutting and accepting DXF file from DIYers with small series request (one or two units). Big Blue Saw, based in Atlanta, did a good job, but it's quite expensive...

Many companies makes PCB. I choose GoldPhoenix, because it seems to be one of the cheapest one, and propose a reasonable price for large PCB. Some manufacturers just refused to take my quote because of the unusual big size, some other gave me really expensive quotes (more than $400 for OSH park !)

With few more parts from WASD Keyboards, I was able to start the final assembly.

<br><img src="/pub/DasMatrix/parts.jpg" width="450">

Assembly
========

I took a risk by going directly with the final parts and bypassing the prototype stage, but it has been worth it.
I'm happy, I didn't make any huge mistake, just a small error of 1 mm on one side of the edge cut, easily fixed with a small file.

No error on the wiring nor the electric side, Everything else fitted and worked perfectly at the first time !
The overall look pretty well :

<br><img src="/pub/DasMatrix/inside_open.jpg" width="450">

Open Hardware ?
===============

All source files, for the plate and the PCB, are available here under Creative Commons BY-NC-SA :

[DasMatrix-3.0.src.zip](/pub/DasMatrix/DasMatrix-3.0.src.zip)

And, guess what, this post has been written with this super keyboard !


