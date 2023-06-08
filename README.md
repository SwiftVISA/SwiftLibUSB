SwiftLibUSB
===========

Swift-based wrapper around LibUSB.

> This repository contains experimental code that is not meant for public use.
> The important Swift classes should be put into a package before it is used.

SwiftLibUSB folder
------------------

This folder contains an Xcode package with all of the Swift code we have
produced. Important classes are located in the Usb and SwiftVisaClasses groups;
the other code is simply an example application that shows how to communicate
with a device. See the README within that folder for more information.

experimental folder
-------------------

This folder contains the C code we created when learning how to use LibUSB.
It exists solely as a reference to us of how we were originally able to
communicate with USB devices so we can replicate it in other code.

better-commandline folder
-------------------------

This folder contains a C command-line program that can be used to send commands
and queries to a USB device. It exists mostly as a reference for how to make
the Swift code work.


