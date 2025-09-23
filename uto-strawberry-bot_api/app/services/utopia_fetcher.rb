# app/services/utopia_fetcher.rb
# Strawberry's fetcher for Utopia game data 💾

require "httparty"

class UtopiaFetcher
  DUMP_URL = "https://utopia-game.com/wol/game/kingdoms_dump/"

  def self.fetch
    resp = HTTParty.get(DUMP_URL)
    unless resp.code == 200
      raise "Failed to fetch dump: #{resp.code}"
    end

    resp.parsed_response
  end

  def self.sync!
    data = fetch
    timestamp = data.first
    kingdoms_data = data.drop(1)

    synced_kingdoms = 0
    skipped_kingdoms = 0
    synced_provinces = 0

    kingdoms_data.each do |kdata|
      begin
        unless kdata.is_a?(Hash)
          Rails.logger.error("[UtopiaFetcher] Skipping malformed kingdom data: #{kdata.inspect}")
          skipped_kingdoms += 1
          next
        end

        if kdata["loc"].nil?
          Rails.logger.warn("[UtopiaFetcher] Skipping kingdom with missing loc: #{kdata.inspect}")
          skipped_kingdoms += 1
          next
        end

        kingdom = Kingdom.find_or_initialize_by(loc: kdata["loc"])
        kingdom.name   = kdata["name"]
        kingdom.stance = stance_as_string(kdata["stance"])
        kingdom.honor  = kdata["honor"]
        kingdom.nw     = kdata["nw"]
        kingdom.save!

        kingdom.provinces.destroy_all
        provinces = kdata["provinces"] || []

        unless provinces.is_a?(Array)
          Rails.logger.warn("[UtopiaFetcher] Kingdom #{kdata['loc']} provinces is not an array: #{provinces.inspect}")
          provinces = []
        end

        provinces.each do |pdata|
          kingdom.provinces.create!(
            loc:       pdata["loc"],
            name:      pdata["name"],
            land:      pdata["land"],
            race:      pdata["race"],
            honor:     pdata["honor"],
            nw:        pdata["nw"],
            protected: pdata["protected"]
          )
          synced_provinces += 1
        end

        synced_kingdoms += 1

      rescue => e
        Rails.logger.error("[UtopiaFetcher] Failed to sync kingdom #{kdata.inspect}: #{e.message}")
        skipped_kingdoms += 1
      end
    end

    Rails.logger.info("[UtopiaFetcher] Sync Summary: #{synced_kingdoms} kingdoms synced, #{synced_provinces} provinces synced, #{skipped_kingdoms} kingdoms skipped.")

    timestamp
  end

  private

  def self.stance_as_string(raw)
    return nil if raw.nil?
    raw.is_a?(Array) ? raw.join(" ") : raw.to_s
  end
end
