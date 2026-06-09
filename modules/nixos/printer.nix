{
  lib,
  config,
  ...
}:
{
  options.jemand771.printer.enable = lib.mkEnableOption "printer configuration";
  config = lib.mkIf config.jemand771.printer.enable {
    services.printing.enable = true;
    hardware.printers = {
      ensurePrinters = [
        {
          name = "Brother-HL-3142CW";
          location = "Home";
          deviceUri = "ipp://192.168.0.8/";
          model = "drv:///cupsfilters.drv/pwgrast.ppd";
          ppdOptions = {
            PageSize = "A4";
          };
        }
      ];
      ensureDefaultPrinter = "Brother-HL-3142CW";
    };
  };
}
