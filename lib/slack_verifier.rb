# frozen_string_literal: true

require "openssl"
require "ougai"

module SlackVerifier
  SLACK_VERSION = "v0"
  MAX_REQUEST_AGE = 300 # 5 minutes

  def self.valid?(request, signing_secret, logger: Ougai::Logger.new($stdout))
    timestamp = request.env["HTTP_X_SLACK_REQUEST_TIMESTAMP"]
    signature = request.env["HTTP_X_SLACK_SIGNATURE"]

    return false if timestamp.nil? || signature.nil?

    # Reject old requests (replay attack protection)
    if Time.now.to_i - timestamp.to_i > MAX_REQUEST_AGE
      logger.warn("Request timestamp too old", timestamp: timestamp, max_age: "#{MAX_REQUEST_AGE}s")
      return false
    end

    # Compute expected signature
    request.body.rewind
    body = request.body.read
    request.body.rewind

    sig_basestring = "#{SLACK_VERSION}:#{timestamp}:#{body}"
    expected_signature = "#{SLACK_VERSION}=" + OpenSSL::HMAC.hexdigest(
      "SHA256",
      signing_secret,
      sig_basestring
    )

    # Constant-time comparison to prevent timing attacks
    secure_compare(expected_signature, signature)
  end

  # Constant-time string comparison
  def self.secure_compare(a, b)
    return false unless a.bytesize == b.bytesize

    l = a.unpack("C*")
    r = 0
    i = -1

    b.each_byte { |byte| r |= byte ^ l[i += 1] }
    r.zero?
  end
end
