# Helium extensions

Helium supports Chromium extensions and can import them from another Chromium
browser during onboarding. Treat this file as the portable extension manifest
for a new computer.

## Setup on a new computer

1. Open Helium and complete its onboarding.
2. Enable Helium services when prompted. Helium uses this service to anonymize
   Chrome Web Store extension downloads and updates.
3. Either import extensions from an existing Chromium browser or install them
   from the [Chrome Web Store](https://chromewebstore.google.com/).
4. Review every extension's permissions before installing it.
5. Add the canonical Chrome Web Store link for each chosen extension below.

## Extension manifest

Add one entry per extension:

```text
- Extension name: https://chromewebstore.google.com/detail/...
```

The bootstrap deliberately does not force-install browser extensions. Manual
installation preserves Helium's permission prompts and avoids committing browser
profile data, cookies, sessions, or extension storage.
