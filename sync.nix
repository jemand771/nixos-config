{ ... }:

{
  services.syncthing = {
    enable = true;
    user = "willy";
    dataDir = "/home/willy";
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      options.urAccepted = 3;
      devices = {
        "nixbox2" = { id = "3E5EDPI-MNYTGMO-OFB3WSZ-GQZPDHR-X2WSUZ7-UUI22ET-2XS37YR-WW6HBAE"; };
        "nixtique" = { id = "YK257QH-FXBWGJK-EXJJ7TN-NRCJZ4Y-TOHZSO6-N6GZA7P-ZL3EWRR-SIORDQU"; };
      };
    };
  };
}
