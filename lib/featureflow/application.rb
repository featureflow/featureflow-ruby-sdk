module Featureflow
  # Validates the configured application tag, sent as the X-Featureflow-Application
  # header on every request so the dashboard can attribute usage per workload.
  #
  # Contract slug (featureflow-client-sdk-testbed/CONTRACT.md): lowercase [a-z0-9._-],
  # max 64 chars. The server sanitises defensively; the SDK validates strictly so a
  # typo is a visible warning here rather than a silently mangled tag there.
  class Application
    PATTERN = /\A[a-z0-9._-]{1,64}\z/.freeze

    # Case is forgiven (lowercased); anything else invalid is dropped with a warning
    # and no X-Featureflow-Application header is sent.
    def self.sanitise(raw)
      return nil if raw.nil? || raw == ''
      unless raw.is_a?(String)
        Featureflow.logger.warn "ignoring application #{raw.inspect} - must be a string"
        return nil
      end
      value = raw.strip.downcase
      unless PATTERN.match?(value)
        Featureflow.logger.warn "ignoring application #{raw.inspect} - must be lowercase " \
                                'a-z, 0-9, dot, underscore or hyphen, max 64 chars'
        return nil
      end
      value
    end
  end
end
