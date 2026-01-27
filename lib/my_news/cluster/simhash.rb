# frozen_string_literal: true

module MyNews
  module Cluster
    module Simhash
      module_function

      # Compute a 64-bit SimHash fingerprint for text
      def compute(text)
        tokens = tokenize(text)
        return 0 if tokens.empty?

        vector = Array.new(64, 0)

        tokens.each do |token|
          hash = fnv1a_64(token)
          64.times do |i|
            if hash[i] == 1
              vector[i] += 1
            else
              vector[i] -= 1
            end
          end
        end

        fingerprint = 0
        64.times do |i|
          fingerprint |= (1 << i) if vector[i] > 0
        end
        fingerprint
      end

      # Hamming distance between two 64-bit fingerprints
      def hamming_distance(a, b)
        (a ^ b).to_s(2).count("1")
      end

      def tokenize(text)
        text
          .downcase
          .gsub(/[^a-z0-9\s]/, "")
          .split
          .reject { |w| w.length < 3 }
          .each_cons(3)
          .map { |trigram| trigram.join(" ") }
      end

      # FNV-1a 64-bit hash
      def fnv1a_64(str)
        hash = 0xcbf29ce484222325
        str.each_byte do |byte|
          hash ^= byte
          hash = (hash * 0x100000001b3) & 0xffffffffffffffff
        end
        hash
      end
    end
  end
end
