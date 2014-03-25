---
title: Linphone and G729 on Opensuse
date: 20140324
tags:
 - Linux
 - VoIP
---


The G729 codec is not a real free software, but may be useful with some SIP providers, as this is the best codec for VoIP, only 8 kbit/s and a reasonable good sound quality.

This codec is only freely available on Linux with Linphone. Other softphones don't provide it.
The main problem is that this codec is provided as binaries only for Ubuntu by the Linphone team. The pre-compiled version of Linphone proposed by OpenSuse doesn't include this plugin.
I tried to backport the binaries from Ubuntu to OpenSuse, but with no luck on the latest version (OpenSuse 13.1, Ubuntu 13.4 and Linphone 3.6.1).

So here is the compile process of Linphone with G729ab support on Opensuse 13.1.


# Compile Linphone

First we need some dependencies:

```
zypper install intltool libeXosip2 libeXosip2-devel libosip2 libosip2-devel speex speex-devel libsoup-devel libvpx-devel libswscale-devel libXv-devel libv4l-devel libtheora-devel alsa-devel libffmpeg-devel glew glew-devel sqlite3 sqlite3-devel libupnp-devel
```
If you experience some dependency conflicts, try switching to Packman repositories. To install it use `zypper ar -n packman http://packman.inode.at/suse/openSUSE_13.1/ packman`.


Then, let's download and compile:

```
wget http://download-mirror.savannah.gnu.org/releases/linphone/stable/sources/linphone-3.6.1.tar.gz
tar -xzvf linphone-3.6.1.tar.gz
cd linphone-3.6.1/
./autogen.sh
./configure  --disable-strict
make BUILD_G729=1
make install
```

Note : 
There is a small bug in the source code. To avoid the following error message, add `--disable-strict` to the `./configure` command.

```
propertybox.c:1103:2: error: call to function ‘linphone_core_upnp_available’ without a real prototype [-Werror=unprototyped-calls]
  if(!linphone_core_upnp_available(lc)) {
  ^
```

# Compile the codec

And now, the G729 codec from Belledonne Communications. Be careful, the source code is licensed under GPLv2 but ITU G729 usage is governed by a patent license to be acquired from Sipro Lab. See here for more informations : http://www.linphone.org/eng/documentation/dev/bcg729.html

```
wget http://download-mirror.savannah.gnu.org/releases/linphone/plugins/sources/bcg729-1.0.0.tar.gz
tar -xzvf bcg729-1.0.0.tar.gz
cd bcg729-1.0.0/
./configure
make
make install
```

You can find more plugins here: http://www.linphone.org/eng/download/.

# Check libraries

* Update library cache :

```
ldconfig
```

* Check if G729 libraries are correctly installed :

```
ldconfig -p | grep 729
```

Now it's ok, G729 codec should appear in the codec windows, you just have to enable it.

![Linphone](/blog/img/linphone-g729.jpg)


