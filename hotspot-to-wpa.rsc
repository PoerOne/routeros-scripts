#!rsc by RouterOS
# RouterOS script: hotspot-to-wpa
# Copyright (c) 2019-2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# add private WPA passphrase after hotspot login
# https://git.eworm.de/cgit/routeros-scripts/about/doc/hotspot-to-wpa.md

:local 0 "hotspot-to-wpa";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global EitherOr;
:global LogPrintExit2;
:global ParseKeyValueStore;

:local MacAddress $"mac-address";
:local UserName $username;
:local Date [ /system/clock/get date ];
:local UserVal [ /ip/hotspot/user/get [ find where name=$UserName ] ];
:local UserInfo [ $ParseKeyValueStore ($UserVal->"comment") ];
:local Hotspot [ /ip/hotspot/host/get [ find where mac-address=$MacAddress authorized ] server ];

:if ([ :len [ /caps-man/access-list/find where comment="--- hotspot-to-wpa above ---" disabled ] ] = 0) do={
  /caps-man/access-list/add comment="--- hotspot-to-wpa above ---" disabled=yes;
  $LogPrintExit2 warning $0 ("Added disabled access-list entry with comment '--- hotspot-to-wpa above ---'.") false;
}
:local PlaceBefore ([ /caps-man/access-list/find where comment="--- hotspot-to-wpa above ---" disabled ]->0);

:if ([ :len [ /caps-man/access-list/find where \
    comment=("hotspot-to-wpa template " . $Hotspot) disabled ] ] = 0) do={
  /caps-man/access-list/add comment=("hotspot-to-wpa template " . $Hotspot) disabled=yes place-before=$PlaceBefore;
  $LogPrintExit2 warning $0 ("Added template in access-list for hotspot '" . $Hotspot . "'.") false;
}
:local Template [ /caps-man/access-list/get ([ find where \
    comment=("hotspot-to-wpa template " . $Hotspot) disabled ]->0) ];

:if ($Template->"action" = "reject") do={
  $LogPrintExit2 info $0 ("Ignoring login for hotspot '" . $Hotspot . "'.") true;
}

# allow login page to load
:delay 1s;

$LogPrintExit2 info $0 ("Adding/updating access-list entry for mac address " . $MacAddress . \
  " (user " . $UserName . ").") false;
/caps-man/access-list/remove [ find where mac-address=$MacAddress comment~"^hotspot-to-wpa: " ];
/caps-man/access-list/add comment=("hotspot-to-wpa: " . $UserName . ", " . $MacAddress . ", " . $Date) \
    mac-address=$MacAddress private-passphrase=($UserVal->"password") ssid-regexp="-wpa\$" place-before=$PlaceBefore;

:local Entry [ /caps-man/access-list/find where mac-address=$MacAddress \
    comment=("hotspot-to-wpa: " . $UserName . ", " . $MacAddress . ", " . $Date) ];
:local PrivatePassphrase [ $EitherOr ($UserInfo->"private-passphrase") ($Template->"private-passphrase") ];
:if ([ :len $PrivatePassphrase ] > 0) do={
  :if ($PrivatePassphrase = "ignore") do={
    /caps-man/access-list/set $Entry !private-passphrase;
  } else={
    /caps-man/access-list/set $Entry private-passphrase=$PrivatePassphrase;
  }
}
:local SsidRegexp [ $EitherOr ($UserInfo->"ssid-regexp") ($Template->"ssid-regexp") ];
:if ([ :len $SsidRegexp ] > 0) do={
  /caps-man/access-list/set $Entry ssid-regexp=$SsidRegexp;
}
:local VlanId [ $EitherOr ($UserInfo->"vlan-id") ($Template->"vlan-id") ];
:if ([ :len $VlanId ] > 0) do={
  /caps-man/access-list/set $Entry vlan-id=$VlanId;
}
:local VlanMode [ $EitherOr ($UserInfo->"vlan-mode") ($Template->"vlan-mode") ];
:if ([ :len $VlanMode] > 0) do={
  /caps-man/access-list/set $Entry vlan-mode=$VlanMode;
}
