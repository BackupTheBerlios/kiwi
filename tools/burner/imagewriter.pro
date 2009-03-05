######################################################################
# Automatically generated by qmake (2.01a) Thu Oct 23 14:13:58 2008
######################################################################

TEMPLATE = app
TARGET = 
DEPENDPATH += .
INCLUDEPATH += .

# Input
HEADERS += DeviceItem.h \
           MainWindow.h \
           Platform.h \
           PlatformLinux.h \
           PlatformWindows.h \
           PlatformMac.h
SOURCES += main.cpp MainWindow.cpp Platform.cpp
unix {
	exists ("/usr/include/hal/libhal.h")
	{
		CONFIG += link_pkgconfig
		PKGCONFIG += hal hal-storage
	}
}
unix:SOURCES += PlatformLinux.cpp
unix:CONFIG += qdbus
macx:SOURCES += PlatformMac.cpp
win32:SOURCES += PlatformWindows.cpp
win32:SDKDIR = $$(WindowsSdkDir)
win32:INCLUDEPATH += E:\WINDDK\3790.1830\inc\wxp $$quote($$SDKDIR\..\v6.0A\include)
win32:LIBS += user32.lib
win32:LIBPATH += $$quote($$SDKDIR\..\v6.0A\Lib)
macx:CONFIG += x86 ppc
macx:LIBS += -framework IOKit
RESOURCES += imagewriter.qrc