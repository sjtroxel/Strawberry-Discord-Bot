# app/services/utopia_fetcher.rb
# Strawberry's fetcher for Utopia game data 💾

require "httparty"

class UtopiaFetcher
  DUMP_URL = "https://utopia-game.com/wol/game/kingdoms_dump/"

  # Grab the latest dump from Utopia
  def self.fetch
    resp = HTTParty.get(DUMP_URL)
    unless resp.code == 200
      raise "Failed to fetch dump: #{resp.code}"
    end

    resp.parsed_response
  end
end