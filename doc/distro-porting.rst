How to port your distribution for debian-subsystem
**************************************************

**distro** directory is distribution modules directory. 
Modules written bash and uses busybox.

You must write 3 function. **tool_init**, **system_init**, **create_user**

**$wget** variable is predefined wget path. You should use it.

Example module available in source code.

Then you must add new distribution module to **debian.conf** file like this

.. code-block:: ini

	[example]
	DESTDIR=/var/example
	DIST=example
	REPO=https://example.org/repo

tool_init
^^^^^^^^^
This functions fetch chroot creation tools and install. You must prefer static compiled binary, appimage, or simple script.

system_init
^^^^^^^^^^^
This function create rootfs. Target rootfs directory is **${DESTDIR}** and distribution name is **${DIST}** Repository adress is **${REPO}**

create_user
^^^^^^^^^^^
This function create subsystem user. Current username is **${USERNAME}**


