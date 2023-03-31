# News, changes and migration by RouterOS Scripts
# Copyright (c) 2019-2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md

:global IfThenElse;
:global RequiredRouterOS;

# News, changes and migration up to change 95 are in global-config.changes!

# Changes for global-config to be added to notification on script updates
:global GlobalConfigChanges {
  96="Added support for notes in 'netwatch-notify', these are included verbatim into the notification.";
  97="Modified 'dhcp-to-dns' to always add A records for names with mac address, and optionally add CNAME records if the host name is available.";
};

# Migration steps to be applied on script updates
:global GlobalConfigMigration {
  97=":local Rec [ /ip/dns/static/find where comment~\"^managed by dhcp-to-dns for \" ]; :if ([ :len \$Rec ] > 0) do={ /ip/dns/static/remove \$Rec; /system/script/run dhcp-to-dns; }";
};
