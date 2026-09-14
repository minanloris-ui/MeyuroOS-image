# MeyuroOS Task Manager panel integration

This Plasma 6 containment-actions plugin extends the panel's native right-click
menu with an **Open Task Manager** action. It launches the distribution-provided
Plasma System Monitor on the Overview page and preserves the panel's standard
context actions.

The plugin is compiled in the image's isolated application-builder stage. New
profiles use it through Plasma shell defaults; existing profiles are migrated
once by `meyuroos-apply-task-manager-integration`.
