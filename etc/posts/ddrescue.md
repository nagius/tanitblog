---
title: How I recovered a dead hard drive with a freezer
date: 20161019
tags: 
 - Linux
 - Filesystem
---

One day, like some others when you're working in IT, somebody bring me an external hard drive which didn't work properly anymore.
Here is the story of this data rescue.

## The victim

Once this drive plugged into my computer, I quickly identified an NTFS partition but the device is unreadable: Windows ask to format it (not a good idea dude !) and Linux say that the partition is corrupted, you have to go
back on Windows and run chkdsk.

I know Windows, this will destroy the data.

## The plan

One solution is to use `ddrescue` to copy as much as data we can read to another drive and then run some repair tools on this copy, not on the original data.

Here is the command. In this example, `sde` is the failed drive and `sdd1` is a spare partition slightly bigger than the drive.

```
ddrescue -B -v -n /dev/sde1 /dev/sdd1 recup.log --force
```

Sometimes when DDRescue encounter an error, the read speed is reduced drastically (from 30MB/s to 2MB/s in my case) leading to a never-ending recovery.
By stopping the process (with CTRL+C) and restarting the command, the read will resume at full speed. That could save a lot of time if there is only a few errors.
A recovery allways take ages, at least numerous hours for each run.

After this first pass, it reported around 300 errors on defective clusters and 16Mb unrecoverable data.

DDRescue is an interesting tool because it can reduce the size of the read and try to get data around the error.
Usually only one bit is in error but the whole block of clusters is marked as failed even if there is still some good data in it.

Let's go for a second pass more fine grained :

```
ddrescue -B -v -c 16 -r 2 /dev/sde1 /dev/sdd1 recup.log --force
```

This time it recovered all data but 320kb still unreadable. We're almost there.
But at this point we reached the limit of the drive's health, we need to chill out. I mean literally. I put the hard drive into my freezer for at least 12 hours (and took an ice cream too but that's unrelated).

Now that the drive is cool let's try a third pass a bit more aggressive :

```
ddrescue -B -v -c 1 -r 4 /dev/sde1 /dev/sdd1 recup.log --force
```

Here only 20kb were not readable but I recovered enough data to mount the partiton and get the files back. Operation succeeded !


### Notes

If your freezer is really cold, your hard drive may not start just straight out of the freezer.
Leave it a couple of minutes outside to warm up, power it up and put it back in.

Once spinning the disk will warm up quickly, so it's a good idea to leave it inside the freezer to keep it cool during the recovery. Use long cables for that. And prepare a
speech if somebody ask you why your laptop is on top of the fridge.

