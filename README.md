# Knkts

A minimal native macOS menu bar app that shows whether a wired network connection is active.

<img width="476" height="246" alt="Screenshot 2026-08-25 at 13 23 31" src="https://github.com/user-attachments/assets/0950d708-4db8-4d45-bdcd-2d18d1b7c1d1" />
<img width="476" height="246" alt="Screenshot 2026-08-25 at 13 22 44" src="https://github.com/user-attachments/assets/d63fe955-69ae-4897-8ccc-4aa9cc9ad9b9" />

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
