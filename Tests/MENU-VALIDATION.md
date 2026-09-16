# 0.2.4 menu change

Replaced status.menu + synthesized performClick with process-owned NSMenu.popUp at the mouse location. Menu tracking is cancelled when the application resigns active. Auto-hide is cancelled before tracking; dismissing the menu does not toggle item visibility. The active menu is retained for the duration of tracking and cleared on return.

Compilation and signature verification passed. The installed settings window and existing Accessibility grant were inspected. End-to-end menu-bar coordinate clicking could not be automated because the Computer Use service reports MenuBarAgent has no clickable window; manual outside-click acceptance remains necessary.
