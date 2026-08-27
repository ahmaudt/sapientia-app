#!/usr/bin/env ruby
# frozen_string_literal: true

# Report the current App Store Connect build and beta review state.
#
# Run bare for a human-readable summary:      ./scripts/asc-status.rb
# Run with --hook to emit SessionStart JSON:  ./scripts/asc-status.rb --hook
#
# This is a single status read, NOT a poll — it makes two API calls and exits.
# It never fails a session: any missing key, network error, or API error exits 0
# with no output, so a machine without the App Store Connect key (or no network)
# starts a session exactly as before.

require 'base64'
require 'json'
require 'net/http'
require 'openssl'

KEY_ID = ENV.fetch('ASC_KEY_ID', '7342AH443J')
ISSUER_ID = ENV.fetch('ASC_ISSUER_ID', 'a0d087ed-5a37-4f9f-9f1a-094e52ae641d')
APP_ID = ENV.fetch('ASC_APP_ID', '6799778629')
KEY_PATH = File.expand_path("~/.appstoreconnect/private_keys/AuthKey_#{KEY_ID}.p8")
HOOK_MODE = ARGV.include?('--hook')
TIMEOUT = 8

# Any failure is silent in hook mode — a status line is never worth blocking on.
def bail(message)
  warn(message) unless HOOK_MODE
  exit 0
end

def mint_token
  key = OpenSSL::PKey::EC.new(File.read(KEY_PATH))
  encode = ->(bytes) { Base64.urlsafe_encode64(bytes).delete('=') }
  header = encode.call(JSON.dump(alg: 'ES256', kid: KEY_ID, typ: 'JWT'))
  payload = encode.call(JSON.dump(iss: ISSUER_ID, exp: Time.now.to_i + 1200, aud: 'appstoreconnect-v1'))
  der = key.sign(OpenSSL::Digest::SHA256.new, "#{header}.#{payload}")
  r, s = OpenSSL::ASN1.decode(der).value.map { |v| v.value.to_s(2).rjust(32, "\x00") }
  "#{header}.#{payload}.#{encode.call(r + s)}"
end

def get(path, token)
  uri = URI("https://api.appstoreconnect.apple.com#{path}")
  request = Net::HTTP::Get.new(uri)
  request['Authorization'] = "Bearer #{token}"
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                             open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
    http.request(request)
  end
  return nil unless response.code.to_i == 200

  JSON.parse(response.body)
end

bail("No App Store Connect key at #{KEY_PATH}.") unless File.file?(KEY_PATH)

token = begin
  mint_token
rescue StandardError => e
  bail("Could not mint an App Store Connect token: #{e.message}")
end

builds = get(
  "/v1/builds?filter%5Bapp%5D=#{APP_ID}&limit=3&include=preReleaseVersion,buildBetaDetail" \
  '&fields%5Bbuilds%5D=version,expired,processingState,preReleaseVersion,buildBetaDetail',
  token
)
bail('App Store Connect did not answer.') if builds.nil?

included = (builds['included'] || []).to_h { |item| [item['id'], item] }
rows = (builds['data'] || []).map do |build|
  attributes = build['attributes']
  version = included.dig(build.dig('relationships', 'preReleaseVersion', 'data', 'id'), 'attributes', 'version')
  detail = included.dig(build.dig('relationships', 'buildBetaDetail', 'data', 'id'), 'attributes') || {}
  {
    label: "#{version} (#{attributes['version']})",
    expired: attributes['expired'],
    processing: attributes['processingState'],
    internal: detail['internalBuildState'],
    external: detail['externalBuildState']
  }
end
bail('No builds found.') if rows.empty?

latest = rows.first
review = get("/v1/betaAppReviewSubmissions?filter%5Bbuild%5D=#{(builds['data'] || []).first['id']}", token)
review_state = review&.dig('data', 0, 'attributes', 'betaReviewState') || 'none'

summary = rows.map do |row|
  flags = [row[:processing], ("EXPIRED" if row[:expired])].compact.join(', ')
  "  #{row[:label].ljust(12)} #{flags.ljust(12)} internal=#{row[:internal]} external=#{row[:external]}"
end.join("\n")

report = <<~REPORT.strip
  App Store Connect — Sapientia (latest #{latest[:label]}, beta review: #{review_state})
  #{summary}
REPORT

if HOOK_MODE
  puts JSON.dump(
    hookSpecificOutput: {
      hookEventName: 'SessionStart',
      additionalContext: report
    }
  )
else
  puts report
end
