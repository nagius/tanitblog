---
title: Ext4 rescue tips
date: 20131111
tags:
 - filesystem
 - Linux
---

A few days ago, I received this message from one of my Linux server :

```
EXT4-fs (mmcblk0p2): error count: 10
EXT4-fs (mmcblk0p2): initial error at 1382852841: htree_dirblock_to_tree:861: inode 268: block 7379
EXT4-fs (mmcblk0p2): last error at 1383888315: htree_dirblock_to_tree:861: inode 267: block 7378
```

And an `ls` show me some entries with red question masks : 

```
# ls -l
total 0
-????????? ? ? ? ?            ? readme.txt
```

It seems there is a hole in my filesystem ! So, after a quick backup, I rebooted the box to force an fsck (with `shutdown -r -F`), as errors was on root partition. But it failed almost immediately, asking for a manual check from the rescue shell:

```
/dev/mmcblk0p2: UNEXPECTED INCONSISTENCY: RUN fsck MANUALLY
(i.e., without -a or -p options)
Give root password for maintenance
(or type CTRL-D to continue)
```

I relaunch a check from the rescue shell, with `fsck -vfy /dev/mmcblk0p2`, but it immediately failed with the following error :

`Error storing directory block information (inode=562, block=0, num=31670): Memory allocation failed`

This problem occurs when datas of an inode are so screwed up that fsck come into an infinite loop and run out of memory.
The solution is to discard this specific inode with debugfs and rerun fsck:

WARNING: dangerous command ! This will wipe some data !

```
# debugfs -w /dev/mmcblk0p2
debugfs: clri <562>
debugfs: quit 
```

But after that, thousand errors from fsck flooding my screen, really bad !

### Superblocks

An other solutions is to run the filesystem check with an alternate superblock. But where is this damn superblock backup ?

Some internet ressources talk about `mkfs -n` that show the position of backup superblocks at creation time.
In fact, this option doesn't do anything, but simulate a creation and show what would have been done.
But it only works if the filesystem has been created with the exact same command.
If it has been created with other options, or resized later, you loose.
The good way is to use dumpe2fs which tell the effective position :

`# dumpe2fs /dev/mmcblk0p2 | grep -i superblock`

Try a fsck with one of theses backups, if you're lucky...

`fsck -b X /dev/...`

### Emergency backup

Before rebooting, if your sixth sense is telling you that things will go totally bad, do a backup of what you can still save, on another computer :

```
# On good machine
netcat -l 3444 >dump.cpio

# On failling machine
cd /
find . | grep  -vE "^(\./dev|\./proc|\./run|\./sys)" | cpio -oa -H crc | netcat <ip_good_machine> 3444
```

Once there is no more hope, when your filesystem is totally dead, I suggest you to use `mkfs -cc`. This will double check the device for bad blocks. Really slow but nearly as good as [DBAN](http://www.dban.org/) for reallocating bad sectors.

Then you can restore the filesystem :

```
# On fixed machine
cd /mnt/mynewfs
netcat -l 3444 | cpio -imv
mkdir dev proc run sys

# On good machine
cat dump.cpio | netcat <ip_fixed_machine> 3444
```

