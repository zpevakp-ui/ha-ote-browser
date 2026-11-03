# OTE Browser (test)

Experimental Home Assistant app with Chromium, Chrome DevTools Protocol (CDP), and a persistent browser profile in `/data/chromium-profile`.

This app **does not send reports to OTE**, does not install signing certificates, and does not configure authentication. The purpose is to validate persistent browser storage and browser-automation feasibility. Unattended qualified signing has **not** been verified.

## Install in Home Assistant

1. Settings > Apps > App store > three-dot menu > Repositories.
2. Add `https://github.com/zpevakp-ui/ha-ote-browser`.
3. Find and install **OTE Browser (test)**.
4. Leave the host port unpublished; never forward CDP to the internet.
5. Start and inspect logs for `Persistent Chromium profile` and `OTE Browser CDP ready`.

The app uses its Home Assistant-provided persistent `/data` volume for the Chromium profile. Test browser persistence through a restart before depending on it.

## Security

The CDP endpoint grants control over the browser and does not authenticate callers. Restrict access to trusted Home Assistant apps, and never expose the endpoint publicly. Chromium runs headless and with `--no-sandbox`; do not treat it as a secure certificate vault.

Do not commit private keys, PKCS#12 files, passwords, session data, OTE credentials, or production reports.
