{ ... }:
{
  # TODO hide behind option
  programs.thunderbird = {
    enable = true;
    profiles.default.isDefault = true;
    profiles.default.settings = {
      # order by date
      "mailnews.default_sort_type" = 18;
      "mailnews.default_news_sort_type" = 18;
      # descending
      "mailnews.default_sort_order" = 2;
      "mailnews.default_news_sort_order" = 2;
      # unthreaded
      "mailnews.default_view_flags" = 0;
      "mailnews.default_news_view_flags" = 0;
    };
  };
  # a note on passwords:
  # while I could _probably_ set up some sort of keyring and shove in my mail passwords automatically,
  # I don't really feel up for that task at the moment.
  # Instead, I let thunderbird prompt me for the password on first launch (and first time sending an email)
  # and tick the "save password" checkbox. Not entirely declarative, but good enough for now.
  # TODO deduplicate much? imap/smtp/thunderbird.enable are all shared
  accounts.email.accounts =
    let
      d39s = {
        imap = {
          host = "mail.d39s.de";
          port = 993;
        };
        smtp = {
          host = "mail.d39s.de";
          port = 465;
        };
      };
      gmx = {
        imap = {
          host = "imap.gmx.net";
          port = 993;
        };
        smtp = {
          host = "mail.gmx.net";
          port = 587;
        };
      };
    in
    builtins.mapAttrs
      (
        name: value:
        value
        // {
          address = name;
          userName = name;
          thunderbird.enable = true;
        }
      )
      {
        "jemand771@gmx.net" = gmx // {
          realName = "Willy";
        };
        "willyhille@gmx.net" = gmx // {
          realName = "Willy Hille";
        };
        "willy.hille@d39s.de" = d39s // {
          realName = "Willy Hille";
          # TODO not really
          primary = true;
        };
        "info@d39s.de" = d39s // {
          realName = "info";
        };
      };
}
