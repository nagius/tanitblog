---
title: How to use alarm syscall in Ruby
date: 20191018
tags:
 - Linux
 - Ruby
---
The other day I wanted to use the alarm(2) syscall in a ruby project.

This is an old unix syscall very useful to implement using signals. It's not for some kind of timeout, but rather trigger some code after a defined amount of time. With no need of a loop. This is basically an asynchronous timer provided by the linux kernel. So if it's in the kernel, why reimplementing it in userland ?

I couldn't find any references using the alarm syscall in ruby. Very few resources came up with these keywords. All solutions proposed on various forums are using sleep within a thread, like this :

```ruby
trap "ALRM" do
    puts "Alarm received!"
end

def alarm
  Thread.new do
      sleep 5
      Process.kill "ALRM", $$
  end
end
```

But this does not provide the same behavior ! Take this example :

```ruby
alarm(5)
sleep(4)
alarm(5)
```

With the above thread implementation, the alarm will be triggered twice, once at 5 sec, and another one at 9 sec. With the real alarm(), the signal would be trigerred only once, at 9 seconds. See `man alarm` for more details.

## The solution

The syscall alarm(2) is part of the standard libc. There is way in ruby to direclty call some C function from dynamic libraries. Here's a good articles about it : https://aonemd.github.io/blog/making-system-calls-from-ruby

I did some test with Fiddle, unfortunately the documentation is not very abundant but after a bit of fiddling around with that lib, I succeeded to find a working setup.
A direct call to the `syscall` function should work but very hardcore, and I could'nt find the `syscall_number` for alarm() on my ARM system. You can find it here for x86_64 system though : https://github.com/torvalds/linux/blob/v3.13/arch/x86/syscalls/syscall_64.tbl

But we can call directly the alarm syscall :

```ruby
require 'fiddle'

libc = Fiddle.dlopen('/lib/arm-linux-gnueabihf/libc.so.6')
alarm = Fiddle::Function.new(libc['alarm'], [Fiddle::TYPE_INT], Fiddle::TYPE_INT)

trap 'ALRM' do
  puts "alarm received !"
end

alarm.call(2)
```

This solution is not ideal, as you need to locate the `libc.6.so` file but it does the job. In that example I'm using Rasbian on a Raspberry pi, hence the armhf architecture.
You can locate yours with `ldconfig -p |  grep libc.so`.
