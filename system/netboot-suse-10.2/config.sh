#!/bin/sh

echo "Configure image: [netboot-suse-10.2]..."
test -f /.profile && . /.profile

#==========================================
# Copy linuxrc to init
#------------------------------------------
cp linuxrc init

exit 0
