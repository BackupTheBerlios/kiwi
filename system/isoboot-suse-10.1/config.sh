#!/bin/sh

echo "Configure image: [isoboot-suse-10.1]..."
test -f /.profile && . /.profile

#==========================================
# Copy linuxrc to init
#------------------------------------------
cp linuxrc init

exit 0
