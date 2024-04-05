Gtk+-Cocoa is a native port of  Gtk+ 1.2 to Mac OS X. It maps Gtk+ widgets and calls to the corresponding Cocoa controls. 
GTK+-Cocoa doesn't need X and retains the Aqua look and feel.
Notice that this is not a port of gdk, so applications that draw their own widgets will have to be rewritten.

Current Status
At present, Gtk+-Cocoa is functional but incomplete. Because of the approach chosen for the port, each Gtk widget had to be mapped
to the corresponding Cocoa control. Given the number of Gtk widgets, many of them have not been mapped yet or only provide partial 
functionality. Furthermore, some Gtk capabilities are not supported by Cocoa. When possible, those capabilities have been implemented, 
but in some cases they simply don't make sense in the Cocoa environment and are not supported.

Installation
Gtk+-Cooca is a Framework. A Xcode project is provided to compile it. Please refer to the testgtk project to see how to include
Gtk+-Cocoa in your applications.

Support
This is an alpha release. I am adding functionality and fixing bugs. If you want some features or bug fixes or if you want to contribute 
to this project contact me at pcostabel@users.sourceforge.net.
