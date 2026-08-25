# Knkts

A minimal native macOS menu bar app that shows whether a wired network connection is active.

- The icon reflects wired connection status.
- The menu lists active wired network services.
- Selecting a service opens macOS Network settings.
- It reads connection state, service name, and service ID only. It does not inspect network activity.

Requires macOS 13 or later.

```sh
make build
open build/Knkts.app
```
