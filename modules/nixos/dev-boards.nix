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

  # Silicon Labs Simplicity Commander for flashing/debugging EFR32 and EFM32 parts.
  # Not in nixpkgs and shipped only as a prebuilt Qt5 bundle, so it is patchelf'd
  # against nixpkgs libs rather than built from source. The bundled Qt5 and J-Link
  # libs under lib/ are kept and picked up automatically by autoPatchelf, and
  # libjlinkarm dlopen()s libudev, hence the runtimeDependencies entry.
  #
  # Only the CLI half of the zip is installed. The GUI (Commander_linux_*) segfaults
  # whenever its Settings menu is opened -- a jump through a garbage pointer in the
  # menu's aboutToShow handler, reproducible on the untouched upstream binary in an
  # FHS sandbox, so not something this derivation can patch around.
  #
  # Upstream serves one unversioned URL and overwrites it on every release, so the
  # hash breaks whenever they publish: bump `version`/`build` and re-fetch then.
  simplicity-commander =
    let
      build = "1v25p1b2000";
      arch =
        {
          x86_64-linux = "x86_64";
          aarch64-linux = "aarch64";
        }
        .${pkgs.stdenv.hostPlatform.system}
          or (throw "simplicity-commander: unsupported system ${pkgs.stdenv.hostPlatform.system}");
    in
    pkgs.stdenv.mkDerivation {
      pname = "simplicity-commander";
      version = "1.25.1";

      src = pkgs.fetchurl {
        url = "https://www.silabs.com/documents/public/software/SimplicityCommander-Linux.zip";
        hash = "sha256-iLBwRJRp6f7UljMdcGomriSAjC2ifGXBQN7GyAGwq58=";
        # silabs.com sits behind Akamai, which 403s curl's default request;
        # browser-like headers (Accept-Encoding in particular) get through.
        curlOptsList = [
          "-A" "Mozilla/5.0 (X11; Linux x86_64; rv:130.0) Gecko/20100101 Firefox/130.0"
          "-H" "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
          "-H" "Accept-Language: en-US,en;q=0.5"
          "-H" "Accept-Encoding: identity"
        ];
      };

      nativeBuildInputs = with pkgs; [ unzip autoPatchelfHook ];

      buildInputs = with pkgs; [
        stdenv.cc.cc.lib
        dbus
        glib
        krb5
        zlib
      ];

      runtimeDependencies = [ pkgs.systemdLibs ];

      sourceRoot = ".";
      dontConfigure = true;
      dontBuild = true;
      dontStrip = true;

      unpackPhase = ''
        runHook preUnpack
        unzip -q $src
        tar -xf SimplicityCommander-Linux/Commander-cli_linux_${arch}_${build}.tar.bz
        runHook postUnpack
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p $out/libexec $out/bin
        cp -r commander-cli $out/libexec/
        ln -s $out/libexec/commander-cli/commander-cli $out/bin/commander-cli
        ln -s $out/libexec/commander-cli/silink $out/bin/silink
        install -Dm444 commander-cli/99-jlink.rules $out/lib/udev/rules.d/99-jlink.rules
        runHook postInstall
      '';

      meta = with pkgs.lib; {
        description = "Silicon Labs Simplicity Commander CLI: flashing and debugging tool for EFR32/EFM32 devices";
        homepage = "https://www.silabs.com/developer-tools/simplicity-studio/simplicity-commander";
        license = licenses.unfree;
        platforms = [ "x86_64-linux" "aarch64-linux" ];
        mainProgram = "commander-cli";
      };
    };
in
{
  environment.systemPackages = [
    genio-tools
    simplicity-commander
    pkgs.segger-jlink-headless
  ];

  # Simplicity Commander talks to WSTK/Silabs boards through their on-board J-Link
  # probe (VID 0x1366), which needs the SEGGER udev rules to be usable as non-root.
  services.udev.packages = [ simplicity-commander ];

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
