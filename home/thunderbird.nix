{ ... }:
{
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
  accounts.email.accounts."willy.hille@d39s.de" = {
    address = "willy.hille@d39s.de";
    userName = "willy.hille@d39s.de";
    realName = "Willy Hille";
    imap = {
      host = "mail.d39s.de";
      port = 993;
    };
    smtp = {
      host = "mail.d39s.de";
      port = 465;
    };
    # TODO not really
    primary = true;
    thunderbird.enable = true;
  };
}
