# MateBook AMD audio fix

Updating the graphics driver on a **Huawei MateBook 14 AMD 2020** (Ryzen 4000H) with AMD's own **Adrenalin "Polaris & Vega"** package makes the built-in speakers much quieter.

The graphics driver itself works fine. The problem is that the installer also replaces the audio drivers of the AMD Audio CoProcessor (ACP) with generic AMD versions. This script switches the audio back to the Huawei drivers and leaves the new graphics driver in place.

## Affected

| | |
|---|---|
| Laptop | Huawei MateBook 14 AMD 2020 (`KLVL-WXX9` / `KLVL-WFE9Q`), Ryzen 7 4800H |
| Audio device | AMD ACP `PCI\VEN_1022&DEV_15E2&SUBSYS_3E331E83` |
| Trigger | AMD Adrenalin 26.5.2 Polaris & Vega (graphics driver 31.0.21925.1001) |

Other Huawei/Honor laptops with a Ryzen 4000/5000 chip and an ACP audio device are probably affected too, but this has not been tested.

## Driver versions

| Device | Good (Huawei) | Quiet (AMD) |
|---|---|---|
| AMD Audio CoProcessor (`amdacpbus`) | **6.0.0.14** | 6.0.1.85 |
| AMD Audio Device (`amdacpafd`) | **6.0.0.10** | 6.0.1.44 |

To check yours: open Device Manager and look at the Driver tab of each device.

## Fix

Run PowerShell as Administrator:

```powershell
.\restore-oem-audio.ps1 -ListOnly   # shows installed and available versions, changes nothing
.\restore-oem-audio.ps1             # switches back to the Huawei drivers
```

Reboot afterwards.

The Huawei drivers are normally still on the PC after Adrenalin installs, so the script only selects them again. If they are missing, reinstall them with Huawei PC Manager first, then run the script. The other parameters (`-BusVersion`, `-AfdVersion`) let you target different OEM versions.

## Why

The Huawei CoProcessor driver ships a 648-byte board configuration file, `amdacpconfig.dat`. AMD's driver ignores it and uses a generic configuration (`acpcfg0001.dat`) plus a DSP firmware image. Patching the AMD package is not an option: the drivers are signed by Microsoft, so any change breaks the signature.

## Huawei file hashes (SHA256)

```
41ba33d70ed430fb7bb1ead8bc1d20337e06eb6173d1f9d098c71b9903259211  amdacpbus.sys       6.0.0.14
023b3474ffda4f2ea70b1da0bb5714196cf77adc5ca016a01033f0b4ed6904c0  amdacpconfig.dat
c7306ce2ee9567ce1f081c34b4fc15cc4cf3f38913f4edd06b004f55212f0590  amdacpbus.inf
56fef4966c4dcc19da6bb292e32679505754e756d8cba77d1cfe8159590e0aee  amdacpafd.sys       6.0.0.10
7d893b20446d8d6b641feaedfe5015876eecc047f7973dfac5c8133c20cd3597  amdacpafd.inf
```

Driver binaries are not included here. They are copyrighted by Huawei and AMD.

## Disclaimer

Use at your own risk. Create a system restore point before running the script.
