# CLAUDE.md

Public repo: documents and fixes quiet speakers on Huawei MateBook 14 AMD 2020 after installing AMD Adrenalin (Polaris & Vega branch). All content in English; keep the README short.

## Files
- `restore-oem-audio.ps1`: the fix. Finds the OEM `amdacpbus.inf` / `amdacpafd.inf` in the DriverStore by `DriverVer` and force-binds them with `UpdateDriverForPlugAndPlayDevicesW` (newdev.dll, `INSTALLFLAG_FORCE`). It must do the bus (PCI `DEV_15E2`) before the child (ACP `DEV_15E2`). The hardware ID passed only selects the device: Windows matches the INF against all of the device's IDs.
- `README.md`: user-facing explanation, version table, hashes.

## Facts (verified on KLVL-WXX9, Windows 11 26200)
- Good: amdacpbus 6.0.0.14 + amdacpafd 6.0.0.10 (Huawei OEM). Bad: 6.0.1.85 + 6.0.1.44 (Adrenalin 26.5.2). Adrenalin also adds amdsafd 1.0.0.9 and amdacpbt 6.0.0.44 (not needed).
- The OEM bus package contains `amdacpconfig.dat` (648 B board config); the AMD package has `acpcfg0001.dat` + `acpimg0001.dat` instead.
- The speaker APO chain (Huawei HWVE + Nahimic) is the same with both drivers.
- Drivers are WHCP-signed and HVCI is on, so modifying the packages is not viable.

## Rules
- Never commit driver binaries (.sys/.dat/.cat/.inf from Huawei/AMD): licensing.
- Test with `-ListOnly` first. A forced reinstall of the same version is harmless (no reboot needed).
