{ pkgs, ... }:

let
  genio-bootrom = pkgs.python3Packages.buildPythonPackage {
    pname = "genio-bootrom";
    version = "1.2.3";
    format = "wheel";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/de/2e/8f70d4a5d54d22a4afdfe3ebb8b1b19c9dad14b1df807f31f1fb06d8b1ec/genio_bootrom-1.2.3-py3-none-any.whl";
      sha256 = "06kajmcz0brj9bca40qqn2wjy5d3swc41difync35739hsnqn7ny";
    };
    doCheck = false;
  };

  fastboot-log-parser = pkgs.python3Packages.buildPythonPackage {
    pname = "fastboot-log-parser";
    version = "0.1.1";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/b0/7e/2e93cf7fd513e8cdd549aa5dbeb8aae55e1852f02ab3e2b3e2e86b3ec012/fastboot_log_parser-0.1.1.tar.gz";
      sha256 = "10pwb7yb85iwzxfabka0whh7ml1jag10i3adfnab30vgqwfbab65";
    };
    pyproject = true;
    build-system = with pkgs.python3Packages; [ setuptools setuptools-scm ];
    propagatedBuildInputs = [ pkgs.python3Packages.simplejson ];
    doCheck = false;
  };

  # MediaTek's Genio board flashing/control CLI (genio-flash, genio-board).
  # Not packaged in nixpkgs, so it's vendored here from PyPI along with its
  # two nixpkgs-missing deps above. Upstream pins gpiod==1.4.0 but nixpkgs
  # only ships the 2.x API; relaxed since only the GPIO-based reset/download
  # path (-c/-r/-d/-p flags) would be affected, not the default FTDI/fastboot
  # flow.
  genio-tools = pkgs.python3Packages.buildPythonApplication {
    pname = "genio-tools";
    version = "1.7.1";
    format = "wheel";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/60/c0/15433ddccecccdd3c60e038fc78b3d70dee6ebbbbd6ee6f1cf3191a3239c/genio_tools-1.7.1-py3-none-any.whl";
      sha256 = "04a04v7yri7sbib1dwhd322zm2s6q4v6gsq8632bnl2l3wwzwg00";
    };
    pythonRelaxDeps = [ "gpiod" ];
    propagatedBuildInputs = with pkgs.python3Packages; [
      genio-bootrom
      fastboot-log-parser
      keyboard
      gpiod
      oyaml
      packaging
      psutil
      pyftdi
      pyusb
      pyudev
    ];
    doCheck = false;
  };
in
{
  environment.systemPackages = [ genio-tools ];

  # udev rules granting non-root USB access (via the "dialout" group) to
  # common development boards: ESP32 boards with native USB-JTAG-Serial and
  # CP210x/CH340/FTDI bridges, plus ARM debuggers (Keil, ST-LINK) and others.
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="303a", ATTR{idProduct}=="1001", MODE="0666", GROUP="dialout"
    SUBSYSTEM=="usb", ATTR{idVendor}=="10c4", ATTR{idProduct}=="ea60", MODE="0666", GROUP="dialout"
    SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="7523", MODE="0666", GROUP="dialout"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="6015", MODE="0666", GROUP="dialout"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0d11", MODE="0666", GROUP="dialout"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0483", MODE="0666", GROUP="dialout"
    
    SUBSYSTEM=="usb", ATTR{idVendor}=="0e8d", ATTR{idProduct}=="201c", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0e8d", ATTR{idProduct}=="0003", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0403", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="gpio", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0e8d", ATTR{idProduct}=="201c", MODE="0660", GROUP="dialout"
  '';
}
