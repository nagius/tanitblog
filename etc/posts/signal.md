---
title: Signal handling and Ruby
date: 20151218
tags:
 - Linux
 - Ruby
---

Since version 2.0.0, signal handling in Ruby can be tricky. I bet if you're here, it's because you've seen this error message :

```
log writing failed. can't be called from trap context
```

or

```
synchronize': can't be called from trap context (ThreadError)
```

The reason is Ruby is now blocking unsafe calls within trap handlers, like Mutex stuff which are widely used (by Logger for example).

You can find more detailed information here about the reasons: [Ruby Best Practices - Implementing signal handlers](http://blog.rubybestpractices.com/posts/ewong/016-Implementing-Signal-Handlers.html).

Two majors tricks exists to work around this. We can find some implementation in many software (Adhearsion, Sensu, Sidekiq...) but they are not widely documented or explained on the web.


The pooling loop
----------------

This one use a global variable to queue the list of received signals and a pooling loop to process them.

```
LOG = Logger.new(STDOUT)

def setup_signals(signals)
    Thread.main[:pending_signals] = []

    signals.each { |signal|
        trap signal do
            Thread.main[:pending_signals] << signal
        end
    }
end

def handle_signals()
    while signal = Thread.main[:pending_signals].shift
        LOG.info "Signal #{signal} received"
    end
end

setup_signals([:HUP, :USR1])
while true
    sleep 1
    handle_signals()
end
```

Be careful, using a global variable is not thread safe without locking, and locking is forbidden in trap context ! Instead, it use an attribute of the main thread as global variable to be thread-safe.

The main drawback is the pooling loop, which add a small delay between the signal is received and the corresponding code is executed.


The self-pipe trick
-------------------

This way of doing it is a little bit more complex but remove the pooling latency. It push the received signal to a pipe which is read using select() within the same process.


```
LOG = Logger.new(STDOUT)

def setup_signals(signals)
    self_read, self_write = IO.pipe

    signals.each { |signal|
        trap signal do
            self_write.puts signal
        end
    }

    self_read
end

def handle_signals(self_read)
    while readable_io = IO.select([self_read])
        signal = readable_io.first[0].gets.strip
        LOG.info "Signal #{signal} received"
    end
end

self_read = setup_signals([:HUP, :USR1])
handle_signals(self_read)
```

This trick is not well-known despite it's a very old one, and not specific to Ruby. You can find references on some unix maiing list in the 90's. I Think the [credit goes to Daniel J. Bernstein](http://cr.yp.to/docs/selfpipe.html)

It's really effective and the self-pipe is thread-safe. But if you don't have a main select loop in your program, it can mess with the architecture.

Celluloid
---------

With Celluloid, you can do it the same way, except there is no (not yet) Celluloid-enabled IO.select(). So the self-pipe trick is not easy to do, unless you spawn another actor just to listen to the pipe.

I came with this code, it's not perfect but it's working. Using an instance variable to queue incoming signals is safe because it's restricted to the actor's thread.

```
require 'celluloid/current'

class MyActor
    include Celluloid
    include Celluloid::Internals::Logger

    def setup_signals(signals)
        @pending_signals = []

        signals.each { |signal|
            trap signal do
                @pending_signals << signal
            end
        }

        every(1) {
            while signal = @pending_signals.shift
                async.handle_signal(signal)
            end
        }

        every(2) { info "Tick" }  # This show the Actor is not blocked
    end

    def handle_signal(signal)
        info "Signal #{signal} received"
    end
end

MyActor.new.setup_signals([:HUP, :USR1])
sleep
```

EventMachine
------------

There is a special trick for EventMachine ([found on the bug tracker](https://github.com/eventmachine/eventmachine/issues/418)). The idea is to postpone the signal processing in the next iteration of the reactor loop to escape the trap context.

```
require 'eventmachine'

LOG = Logger.new(STDOUT)

def setup_signals(signals)
    signals.each { |signal|
        trap signal do
            EM.add_timer(0) {
                handle_signal(signal)
            }
        end
    }
end

def handle_signal(signal)
    LOG.info "Signal #{signal} received"
end

EM.run {
    setup_signals([:HUP, :USR1])

    EM::PeriodicTimer.new(2) {
        LOG.info "Tick" # This show the main loop is not blocked
    }
}
```

I hope this will be useful !
