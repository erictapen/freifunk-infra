# Stages

# 1. Generiere State

In der ersten Phase wird State generiert, z.B. das fastd-Schlüsselpaar.

State sollte sich möglichst nur in '/var/lib/freifunk-vpn/ffs/' befinden.

# 1. Ist der Node schon registriert?

Frage per DNS den AAAA Record für die IP `ffs-${MAC ohne ':'}-${Erste 12 Zeichen des fastd-pubkeys}.segassign.freifunk-stuttgart.de` ab. Wenn es einen record gibt, zeigt der letzte Block der IPv6 das Segment an.

Beispiel:

```sh
$ host -t AAAA ffs-8416f9e8a8b8-3a0f90c2ce69.segassign.freifunk-stuttgart.de
ffs-8416f9e8a8b8-3a0f90c2ce69.segassign.freifunk-stuttgart.de has IPv6 address 2001:2:0:711::17
```

Das resultierende Segment `17` ist u.a. Tübingen. In diesem Fall kann mit Schritt X weitergemacht werden.

Wenn der Record leer ist, dann ist der Node noch nicht registriert:

``
Host ffs-8416f9e8a8b8-3a0f90c2ce68.segassign.freifunk-stuttgart.de not found: 3(NXDOMAIN)
``

In diesem Fall muss zuerst das Onboarding erledigt werden.

## 2. Onboarding

Baue fastd-Verbindung zum Onboarder auf `gw07.gw.freifunk-stuttgart.de` auf.

Die ständig über HTTP verfügbare Seite `/cgi-bin/nodeinfo` beinhaltet ein JSON mit dieser Form:

```json
"software": {
  "firmware": {
     # base = "gluon-v2016.2.7";
     "release": "1.3+2017-09-13-g.d722c26-s.b0e5e48",
     "isGluon" = false
  },
  "owner": {
    "contact": "mail@example.com"
  }
}
```
Das soll so etwas wie ein Minimalstandard sein. Alle Felder sind "standardkonform", außer `software.firmware.isGluon = false`. Diese Flag soll die Möglichkeit lassen, nach Meshteilnehmern dieser Art zu filtern. Außerdem soll durch das verpflichtende Setzen von `owner.contact` sichergestellt werden, dass die Person ansprechbar ist.

Hier zum Vergleich eine echte Gluon-Antwort nach erfolgreichem Onboarding:

```json
{
  "software": {
    "autoupdater": {
      "branch": "stable",
      "enabled": true
    },
    "batman-adv": {
      "version": "2016.2",
      "compat": 15
    },
    "fastd": {
      "version": "v18",
      "enabled": true
    },
    "firmware": {
      "base": "gluon-v2016.2.7",
      "release": "1.3+2017-09-13-g.d722c26-s.b0e5e48"
    },
    "status-page": {
      "api": 1
    }
  },
  "network": {
    "addresses": [
      "fd21:711::8616:f9ff:fee8:a8b8",
      "fd21:b4dc:4b17:0:8616:f9ff:fee8:a8b8",
      "fe80::8616:f9ff:fee8:a8b8"
    ],
    "mesh": {
      "bat0": {
        "interfaces": {
          "wireless": [
            "0a:6b:b2:1f:40:81",
            "0a:6b:b2:1f:40:82"
          ],
          "tunnel": [
            "0a:6b:b2:1f:40:87"
          ],
          "other": [
            "0a:6b:b2:1f:40:83"
          ]
        }
      }
    },
    "mac": "84:16:f9:e8:a8:b8"
  },
  "location": {
    "zip": "72074"
  },
  "owner": {
    "contact": "anfrage@freifunk-neckaralb.de"
  },
  "system": {
    "site_code": "ffs"
  },
  "node_id": "8416f9e8a8b8",
  "hostname": "ffs-tue-elefantengehege",
  "hardware": {
    "model": "TP-Link TL-WR1043N/ND v4",
    "nproc": 1
  }
}
```

TODO:

In einem zweiten Schritt prüft der Onboarder, ob eine laufende Batman-Instanz auch wirklich die angegebene MAC hat. Am liebsten würde ich ja eine zufällige MAC angeben, aber ich weiß nicht, wie batman die schluckt...

Alternativ müsste man halt batctl die MAC generieren lassen und denn dynamisch in die nodeinfo einbringen (Oh Graus). 




Sobald die fastd-Verbindung von der Gegenseite terminiert wurde kann mit Schritt 2 geschaut werden, ob das Onboarding geklappt hat.
