#!rsc by RouterOS
# RouterOS script: hotspot-to-wpa%TEMPL%
# Copyright (c) 2019-2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# add private WPA passphrase after hotspot login
# https://git.eworm.de/cgit/routeros-scripts/about/doc/hotspot-to-wpa.md
#
# !! This is just a template to generate the real script!
# !! Pattern '%TEMPL%' is replaced, paths are filtered.

:local 0 "hotspot-to-wpa%TEMPL%";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global EitherOr;
:global LogPrintExit2;
:global ParseKeyValueStore;
:global ScriptLock;

$ScriptLock $0;

:local MacAddress $"mac-address";
:local UserName $username;

:if ([ :typeof $MacAddress ] = "nothing" || [ :typeof $UserName ] = "nothing") do={
  $LogPrintExit2 error $0 ("This script is supposed to run from hotspot on login.") true;
}

:local Date [ /system/clock/get date ];
:local UserVal ({});
:if ([ :len [ /ip/hotspot/user/find where name=$UserName ] ] > 0) do={
  :set UserVal [ /ip/hotspot/user/get [ find where name=$UserName ] ];
}
:local UserInfo [ $ParseKeyValueStore ($UserVal->"comment") ];
:local Hotspot [ /ip/hotspot/host/get [ find where mac-address=$MacAddress authorized ] server ];

:if ([ :len [ /caps-man/access-list/find where comment="--- hotspot-to-wpa above ---" disabled ] ] = 0) do={
:if ([ :len [ /interface/wifiwave2/access-list/find where comment="--- hotspot-to-wpa above ---" disabled ] ] = 0) do={
  /caps-man/access-list/add comment="--- hotspot-to-wpa above ---" disabled=yes;
  /interface/wifiwave2/access-list/add comment="--- hotspot-to-wpa above ---" disabled=yes;
  $LogPrintExit2 warning $0 ("Added disabled access-list entry with comment '--- hotspot-to-wpa above ---'.") false;
}
:local PlaceBefore ([ /caps-man/access-list/find where comment="--- hotspot-to-wpa above ---" disabled ]->0);
:local PlaceBefore ([ /interface/wifiwave2/access-list/find where comment="--- hotspot-to-wpa above ---" disabled ]->0);

:if ([ :len [ /caps-man/access-list/find where \
:if ([ :len [ /interface/wifiwave2/access-list/find where \
    comment=("hotspot-to-wpa template " . $Hotspot) disabled ] ] = 0) do={
  /caps-man/access-list/add comment=("hotspot-to-wpa template " . $Hotspot) disabled=yes place-before=$PlaceBefore;
  /interface/wifiwave2/access-list/add comment=("hotspot-to-wpa template " . $Hotspot) disabled=yes place-before=$PlaceBefore;
  $LogPrintExit2 warning $0 ("Added template in access-list for hotspot '" . $Hotspot . "'.") false;
}
:local Template [ /caps-man/access-list/get ([ find where \
:local Template [ /interface/wifiwave2/access-list/get ([ find where \
    comment=("hotspot-to-wpa template " . $Hotspot) disabled ]->0) ];

:if ($Template->"action" = "reject") do={
  $LogPrintExit2 info $0 ("Ignoring login for hotspot '" . $Hotspot . "'.") true;
}

# allow login page to load
:delay 1s;

$LogPrintExit2 info $0 ("Adding/updating access-list entry for mac address " . $MacAddress . \
  " (user " . $UserName . ").") false;
/caps-man/access-list/remove [ find where mac-address=$MacAddress comment~"^hotspot-to-wpa: " ];
/interface/wifiwave2/access-list/remove [ find where mac-address=$MacAddress comment~"^hotspot-to-wpa: " ];
/caps-man/access-list/add private-passphrase=($UserVal->"password") ssid-regexp="-wpa\$" \
/interface/wifiwave2/access-list/add passphrase=($UserVal->"password") ssid-regexp="-wpa\$" \
    mac-address=$MacAddress comment=("hotspot-to-wpa: " . $UserName . ", " . $MacAddress . ", " . $Date) \
    action=reject place-before=$PlaceBefore;

:local Entry [ /caps-man/access-list/find where mac-address=$MacAddress \
:local Entry [ /interface/wifiwave2/access-list/find where mac-address=$MacAddress \
    comment=("hotspot-to-wpa: " . $UserName . ", " . $MacAddress . ", " . $Date) ];
# NOT /caps-man #
:set ($Template->"private-passphrase") ($Template->"passphrase");
# NOT /caps-man #
:local PrivatePassphrase [ $EitherOr ($UserInfo->"private-passphrase") ($Template->"private-passphrase") ];
:if ([ :len $PrivatePassphrase ] > 0) do={
  :if ($PrivatePassphrase = "ignore") do={
    /caps-man/access-list/set $Entry !private-passphrase;
    /interface/wifiwave2/access-list/set $Entry !passphrase;
  } else={
    /caps-man/access-list/set $Entry private-passphrase=$PrivatePassphrase;
    /interface/wifiwave2/access-list/set $Entry passphrase=$PrivatePassphrase;
  }
}
:local SsidRegexp [ $EitherOr ($UserInfo->"ssid-regexp") ($Template->"ssid-regexp") ];
:if ([ :len $SsidRegexp ] > 0) do={
  /caps-man/access-list/set $Entry ssid-regexp=$SsidRegexp;
  /interface/wifiwave2/access-list/set $Entry ssid-regexp=$SsidRegexp;
}
:local VlanId [ $EitherOr ($UserInfo->"vlan-id") ($Template->"vlan-id") ];
:if ([ :len $VlanId ] > 0) do={
  /caps-man/access-list/set $Entry vlan-id=$VlanId;
  /interface/wifiwave2/access-list/set $Entry vlan-id=$VlanId;
}
# NOT /interface/wifiwave2 #
:local VlanMode [ $EitherOr ($UserInfo->"vlan-mode") ($Template->"vlan-mode") ];
:if ([ :len $VlanMode] > 0) do={
  /caps-man/access-list/set $Entry vlan-mode=$VlanMode;
  /interface/wifiwave2/access-list/set $Entry vlan-mode=$VlanMode;
}
# NOT /interface/wifiwave2 #

:delay 2s;
/caps-man/access-list/set $Entry action=accept;
/interface/wifiwave2/access-list/set $Entry action=accept;
