# frozen_string_literal: true

require "debug_me"

module MyNews
  module Fetch
    # SOCKS5 proxy wrapper for routing feed fetches through Tor.
    # Requires a running Tor service (default: localhost:9050).
    #
    # Usage in config/defaults.yml:
    #   fetch:
    #     tor:
    #       enabled: false
    #       host: 127.0.0.1
    #       port: 9050
    module TorProxy
      include DebugMe

      module_function

      def endpoint(config: MyNews.config)
        tor_config = config.fetch.respond_to?(:tor) ? config.fetch.tor : nil
        return nil unless tor_config
        return nil unless tor_enabled?(tor_config)

        host = tor_value(tor_config, :host, "127.0.0.1")
        port = tor_value(tor_config, :port, 9050)

        Async::HTTP::Endpoint.parse(
          "http://proxy",
          scheme: "http",
          hostname: host,
          port: port
        )
      end

      def available?(config: MyNews.config)
        ep = endpoint(config: config)
        return false unless ep

        require "socket"
        host = tor_value(config.fetch.tor, :host, "127.0.0.1")
        port = tor_value(config.fetch.tor, :port, 9050)

        socket = TCPSocket.new(host, port)
        socket.close
        true
      rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, SocketError
        false
      end

      def tor_enabled?(tor_config)
        if tor_config.respond_to?(:enabled)
          tor_config.enabled
        elsif tor_config.respond_to?(:[])
          tor_config[:enabled] || tor_config["enabled"]
        else
          false
        end
      end

      def tor_value(tor_config, key, default)
        if tor_config.respond_to?(key)
          tor_config.send(key) || default
        elsif tor_config.respond_to?(:[])
          tor_config[key] || tor_config[key.to_s] || default
        else
          default
        end
      end
    end
  end
end
