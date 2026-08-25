# Knkts

A minimal native macOS menu bar app that shows whether a wired network connection is active.

<img width="400" alt="connected-rounded" src="https://github.com/user-attachments/assets/fe452a97-45ca-42bf-9406-d7ce12959dbf" />
<img width="400" alt="disconnected-rounded" src="https://github.com/user-attachments/assets/cabcca3c-029c-406d-a4dc-15b73adf31ca" />

<br/>
<br/>


- The icon reflects wired connection status.
- The menu lists active wired network services.
- Selecting a service opens macOS Network settings.
- It reads connection state, service name, and service ID only. It does not inspect network activity.

Requires macOS 13 or later.

```sh
make build
open build/Knkts.app
```
