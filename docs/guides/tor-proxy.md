# Tor Proxy

MyNews can route feed fetches through a Tor SOCKS5 proxy for privacy.

## Setup

Install Tor:

=== "macOS"

    ```bash
    brew install tor
    brew services start tor
    ```

=== "Linux"

    ```bash
    sudo apt install tor
    sudo systemctl start tor
    ```

Tor listens on `127.0.0.1:9050` by default.

## Configuration

Enable in `defaults.yml`:

```yaml
fetch:
  tor:
    enabled: true
    host: "127.0.0.1"
    port: 9050
```

## How It Works

When enabled, the `TorProxy` class wraps HTTP requests through a SOCKS5 proxy. All feed fetches are routed through Tor, hiding your IP from feed servers.

The proxy is managed in `lib/my_news/fetch/tor_proxy.rb`.
