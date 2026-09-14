# MeyuroOS update KCM

This Plasma 6 System Settings module presents the safe, fixed update actions
provided by `bootc`:

- read the current and staged deployment;
- check the image registry for an update;
- download and stage the latest image;
- queue a rollback to the previous deployment;
- restart when the user explicitly confirms it.

System status, update, rollback, and restart operations are launched through
`pkexec`, so the desktop's PolicyKit authentication dialog remains the security
boundary. An administrator password may therefore be requested during normal
use. The module never accepts a command or image reference from QML or from user
input.

The `Containerfile` builds this module in a separate stage and copies only the
installed runtime files into MeyuroOS. After installing the resulting image, the
module can be opened from **System Settings → System Administration → MeyuroOS
Updates**, or for development with:

```bash
kcmshell6 kcm_meyuro_update
```
