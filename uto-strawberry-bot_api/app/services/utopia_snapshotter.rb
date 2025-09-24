# app/services/utopia_snapshotter.rb
# Saves a KingdomSnapshot record for each kingdom based on the current DB state
class UtopiaSnapshotter
  # call with the timestamp returned from UtopiaFetcher.sync! (string or Time)
  def self.save_snapshots!(snapshot_time = Time.current)
    t = snapshot_time.is_a?(String) ? Time.parse(snapshot_time) : snapshot_time.to_time

    Kingdom.find_each do |k|
      next if k.loc.blank? # defensive

      total_land = k.provinces.sum(:land) || 0
      total_honor = k.provinces.sum(:honor) || 0

      KingdomSnapshot.create!(
        kingdom: k,
        loc: k.loc,
        snapshot_time: t,
        total_land: total_land,
        total_honor: total_honor,
        provinces: k.provinces.map { |p|
          {
            loc: p.loc,
            name: p.name,
            land: p.land,
            honor: p.honor,
            nw: p.nw,
            protected: p.protected,
            race: p.race
          }
        }
      )
    end
  end
end
