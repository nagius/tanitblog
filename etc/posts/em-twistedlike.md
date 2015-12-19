---
title: EventMachine is good but...
date: 20151214
tags:
 - Linux
 - Ruby
---

...not as good as Twisted.

I used to be an heavy user of Twisted framework, in Python, but as I prefer Ruby, I switched to EventMachine for one of my new project. And I have to say, I'm really disappointed. Usually, Ruby frameworks and modules are better than their equivalent in other languages, but not this time.

EventMachine is quite ok, but it miss a lot of functionalities we find in Twisted. Basic stuff, for example the ability to instantiate already fired Deferred, chain nested Deferred, join multiple Deferred in one, spawn thread that fire Deferred...

PerspectiveBroker protocol is also awesome and as no equivalent in Ruby. There is just no RPC libs for EventMachine. Generally speaking, all networking libraries are much more integrated in Twisted than their counterpart in EventMachine.

But the main missing point is the error management within the callback chain. There is just nothing helpful, you have to deal manually with exceptions. 

The Twisted way, with the two cross-chained callbacks is really smart and convenient. Basically, here is how it works : 

 * Errback and Callback are two synchronized chains of callbacks. 
 * Each time one success, it execute the next callback with the result of the previous one as parameter. 
 * Each time one fail, it execute the next errback with the exception as parameter.


<br>![Deferred](/blog/img/deferred-process.png)

See the [Twisted documentation](http://twistedmatrix.com/documents/12.0.0/core/howto/defer.html) for more details.

So I extended EM with a little bit of monkey patching to get te same behavior. You can find the gem on github: [em-twistedlike](https://github.com/nagius/em-twistedlike). 
With this, development is less painful and closer to Twisted spirit but still not really enjoyable.

A reimplementation of PerspectiveBroker in EventMachine would be really nice too, but it's a lot of work, maybe another time.


Sadly, the project seems to be dead ([see comments on the mailing list](https://groups.google.com/forum/#!topic/eventmachine/9g7oTzmYERo)). I tried to get some information via IRC, no luck... Many people are forking it to add missing functionalities, for example [Sensu-em](https://github.com/sensu/sensu-em) and [EventMachine-LE](https://github.com/ibc/EventMachine-LE).

For new projects, some people recommend [Celluloid](https://github.com/celluloid/celluloid), an implementation of the "Actor model". It's a different approach, heavily multi-threaded, but I will give it a try for my next project.



