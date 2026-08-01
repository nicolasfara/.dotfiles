{ ... }:

{
  # udev rules granting non-root USB access (via the "dialout" group) to
  # common ESP32 boards: the native USB-JTAG-Serial debug unit plus the
  # CP210x/CH340/FTDI USB-to-serial bridges used by other ESP32 dev boards.
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="303a", ATTR{idProduct}=="1001", MODE="0666", GROUP="dialout"
    SUBSYSTEM=="usb", ATTR{idVendor}=="10c4", ATTR{idProduct}=="ea60", MODE="0666", GROUP="dialout"
    SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="7523", MODE="0666", GROUP="dialout"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="6015", MODE="0666", GROUP="dialout"
  '';
}
