# SSH Tunnel for Remote Dev Access

## Why

The dev server (192.168.254.170) runs the frontend behind nginx on port 80 over HTTP. Microsoft MSAL (used for Azure AD login) requires the Web Crypto API, which browsers only expose in **secure contexts**: HTTPS or `localhost`.

Accessing `http://192.168.254.170` directly results in a blank page because MSAL crashes at startup (`BrowserAuthError: crypto_nonexistent`).

An SSH tunnel maps a local port to the remote server, so your browser sees `localhost` — a secure context — and the Crypto API becomes available.

## Command

```bash
ssh -L 3000:localhost:80 cm-dev@192.168.254.170
```

Then open http://localhost:3000 in your browser.

## How It Works

```
Your machine                    Remote server (192.168.254.170)
┌──────────────┐                ┌──────────────┐
│ Browser      │                │ nginx (:80)  │
│ localhost:3000 ──── SSH ────► │  localhost:80 │
└──────────────┘                └──────────────┘
```

- `-L 3000:localhost:80` — binds port 3000 on your local machine and forwards traffic through the SSH connection to `localhost:80` on the remote machine (nginx).
- `cm-dev@192.168.254.170` — the SSH user and host.
- Traffic flows: **your browser** → `localhost:3000` → SSH tunnel → remote `localhost:80` (nginx) → frontend/backend.
- Since your browser is connecting to `localhost`, it treats it as a secure context and the Crypto API is available.

## Notes

- The SSH session must stay open for the tunnel to work. Add `-N` to skip opening a shell if you only need the tunnel:
  ```bash
  ssh -N -L 3000:localhost:80 cm-dev@192.168.254.170
  ```
- If port 3000 is already in use locally, pick another port (e.g. `8080`):
  ```bash
  ssh -L 8080:localhost:80 cm-dev@192.168.254.170
  ```
  Then access http://localhost:8080.
