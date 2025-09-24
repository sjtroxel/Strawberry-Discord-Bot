# app/services/discord_notifier.rb
# Sends messages to a Discord channel via webhook.
# Example usage:
#   DiscordNotifier.send_message("Hello world!")

require 'net/http'
require 'uri'
require 'json'

class DiscordNotifier
  WEBHOOK_URL = ENV['DISCORD_WEBHOOK_URL'] || 'https://canary.discord.com/api/webhooks/1420452485482676244/sH1mY06lpYIr7M2w8WsBPLmtvhhA-zRdhCFwt5KEVb5gs32WzKrqBsk9V3_cwdAHCzpy'

  def self.send_message(message)
    return unless WEBHOOK_URL.present?

    uri = URI.parse(WEBHOOK_URL)
    header = { 'Content-Type': 'application/json' }

    payload = {
        username: 'Strawberry',
        embeds: [
            {
            title: "Notification",
            description: message,
            color: 0xFF69B4 # pink-ish color
            }
        ]
        }.to_json

    begin
      response = Net::HTTP.post(uri, payload, header)
      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.error("[DiscordNotifier] Failed to send message: #{response.code} #{response.body}")
      end
    rescue => e
      Rails.logger.error("[DiscordNotifier] Error sending message: #{e.message}")
    end
  end
end