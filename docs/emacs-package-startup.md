# Emacs package startup

## Repeated Quelpa no-upgrade messages

`Newer package has been installed. Not upgrading.` comes from `quelpa-build`. A `:quelpa` use-package declaration normally calls Quelpa on each evaluation, even when the package is already installed. A checkout/version comparison can then decide that there is nothing to install and print this message. `[4 times]` is Emacs combining repeated identical messages; it is not a count of newly installed packages.

In `~/.emacs`, the `quelpa-use-package` declaration now sets this built-in option in `:init`, before the integration is loaded:

```elisp
(setq quelpa-use-package-inhibit-loading-quelpa t)
```

The integration checks `package-installed-p` and skips the startup Quelpa call for installed packages. Missing packages still follow their configured recipes. This avoids unnecessary package operations rather than hiding messages or errors. Existing package configuration and mode activation still run.

Startup declarations do not monitor recipe changes. To update intentionally, use `M-x quelpa-upgrade` for one package or `M-x quelpa-upgrade-all` for cached Quelpa recipes. Existing update messages and errors remain available. After changing a recipe for an installed package, explicitly invoke Quelpa with that recipe and `:upgrade t`; startup skips it while the package remains installed.

The option takes effect on the next startup. Setting it in the running session affects declarations expanded afterward; it does not rewrite declarations already expanded or delayed during the current startup.

The original init was backed up in `~/emacstools/backup/` before editing. Verification uses the installed integration's actual handler with installed/missing package cases and checks that the configured recipe is passed through unchanged. No full init evaluation or network package update is needed.

## Weekly update check

`quelpa-upgrade-interval` is set to `7`. The startup hook schedules `quelpa-upgrade-all-maybe` after 15 idle seconds, allowing the main init to finish first. It does nothing if the previous weekly run is less than seven days old. When due, it checks and upgrades cached Quelpa packages using normal version checks, including Quelpa itself according to its existing self-upgrade setting. This is limited to Quelpa-managed packages, not all ELPA packages.

Quelpa persists the run date in `~/.emacs.d/quelpa/last_upgrade`. With no timestamp, the first eligible startup runs the check. Once the call completes, the timestamp prevents the same weekly check on subsequent startups. Messages about unchanged versions can still appear during that weekly run. Errors are not hidden; an error that exits the upgrade call prevents the timestamp write and allows a later startup to retry. Individual errors handled internally by Quelpa may still allow the overall call to complete.

No destructive `force` argument is passed: local changes are not deliberately discarded. This is a check on startup, not a background service or a weekly timer while one Emacs session stays open indefinitely. If Emacs was closed on the due date, the next startup checks after the idle delay. Reloading the scheduling function cancels any previous pending timer before scheduling another.

Verification exercises Quelpa's installed timestamp logic with a mocked upgrade operation: first run, repeat within seven days, overdue run and error/retry behavior. No network update was performed during verification.
