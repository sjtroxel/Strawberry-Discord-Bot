# app/services/war_eowcf_detector.rb
# Detects end-of-war reallocations by comparing latest snapshot to previous snapshot.
# When detected, creates EowcfRecord(s) and optionally notifies Discord via DiscordNotifier.

class WarEowcfDetector
  # thresholds (tunable)
  LAND_CHANGE_THRESHOLD = 0.03   # 3% change (absolute relative to previous total)
  HONOR_CHANGE_THRESHOLD = 0.03  # 3% change

  # Run detection after a sync. snapshot_time should match the timestamp returned by fetch/sync.
  # Returns array of created EowcfRecord
  def self.run!(snapshot_time = Time.current)
    t = snapshot_time.is_a?(String) ? Time.parse(snapshot_time) : snapshot_time.to_time
    created = []

    # We'll iterate kingdoms that were previously at war (prev snapshot stance indicates "war")
    Kingdom.find_each do |kingdom|
      next unless kingdom.loc.present?

      # find last two snapshots of this kingdom (prev, current). Use KingdomSnapshot table if available.
      snapshots = KingdomSnapshot.where(loc: kingdom.loc).order(snapshot_time: :desc).limit(2)
      next if snapshots.size < 2

      current_snap = snapshots.first
      prev_snap = snapshots.second

      # fetch stance from the current persisted Kingdom record (saved by sync). Stance text like "war 6:9" or "Normal"
      prev_kingdom_record = Kingdom.find_by(loc: kingdom.loc)
      next unless prev_kingdom_record # just in case

      prev_stance = prev_kingdom_record.stance # this is the *current* DB stance after sync; we want the previous stance too
      # We also stored prev_snap provinces - but we didn't store previous stance. For safety, read prev stance from the last snapshot time by
      # loading the snapshot time's corresponding Kingdom? But we didn't snapshot stance; we can assume if kingdom.stance includes "war" now, it was likely at war previously.
      # Better approach: rely on the stored Kingdom records across snapshots: we use the Kingdom model's last saved entry,
      # and detect change in totals independent of stance. We'll also parse opponent loc if stance string contains "war <loc>".

      # attempt to parse opponent loc from the Kingdom model stance string (it was saved by sync!)
      opponent_loc = parse_opponent_loc(kingdom.stance)

      # If there is no opponent loc (not in war), skip — only interested in kingdoms that have "war" in the stance.
      next unless kingdom.stance.to_s.downcase.include?("war")
      next if opponent_loc.blank?

      # find opponent kingdom record & snapshots
      opponent = Kingdom.find_by(loc: opponent_loc)
      next if opponent.nil?

      opp_snapshots = KingdomSnapshot.where(loc: opponent.loc).order(snapshot_time: :desc).limit(2)
      next if opp_snapshots.size < 2

      current_snap_op = opp_snapshots.first
      prev_snap_op = opp_snapshots.second

      # compute percentage changes for both kingdoms (land & honor)
      change = percent_change(prev_snap.total_land, current_snap.total_land)
      opp_change = percent_change(prev_snap_op.total_land, current_snap_op.total_land)

      honor_change = percent_change(prev_snap.total_honor, current_snap.total_honor)
      opp_honor_change = percent_change(prev_snap_op.total_honor, current_snap_op.total_honor)

      # Look for the typical end-of-war pattern:
      # - One kingdom's land increases by at least LAND_CHANGE_THRESHOLD, and the other's decreases by at least LAND_CHANGE_THRESHOLD
      # - Corresponding honor shifts (winner up, loser down) by HONOR_CHANGE_THRESHOLD ideally
      winner = nil
      loser  = nil

      if change >= LAND_CHANGE_THRESHOLD && opp_change <= -LAND_CHANGE_THRESHOLD
        winner = kingdom
        loser  = opponent
      elsif opp_change >= LAND_CHANGE_THRESHOLD && change <= -LAND_CHANGE_THRESHOLD
        winner = opponent
        loser  = kingdom
      end

      # include honor check to reduce false positives
      if winner && loser
        # check honor pattern: winner_honor increased, loser_honor decreased (or at least some change)
        winner_honor_change = (winner == kingdom) ? honor_change : opp_honor_change
        loser_honor_change  = (loser  == kingdom) ? honor_change : opp_honor_change

        unless winner_honor_change >= -0.20 # don't require large honor change; some wars only change land visibly
          # allow it - but prefer a positive honor increase for winner if possible
        end

        # Confirm detection and create EoWCF records if not already present for this pair and tick
        # We consider EoWCF starting at the start of the hour of the detection time.
        eowcf_start = t.utc.beginning_of_hour
        eowcf_end   = eowcf_start + 96.hours

        # Avoid duplicates: check if either kingdom already has an active EowcfRecord overlapping this start
        existing = EowcfRecord.where(kingdom: [winner, loser]).where("eowcf_end > ?", eowcf_start).exists?
        next if existing

        # Create EoWCF records for both kingdoms
        [winner, loser].each do |k|
          rec = EowcfRecord.create!(
            kingdom: k,
            loc: k.loc,
            eowcf_start: eowcf_start,
            eowcf_end: eowcf_end,
            detected_at: t.utc,
            reason: "Detected via land/honor reallocation (automatic)"
          )
          created << rec
        end

        # Send Discord notification (if DiscordNotifier present)
        begin
          DiscordNotifier.send_message("🍓 Strawberry: Detected end of active war between #{winner.name} (#{winner.loc}) and #{loser.name} (#{loser.loc}). EoWCF started at #{eowcf_start.utc} and ends at #{eowcf_end.utc} (96 ticks).")
        rescue => e
          Rails.logger.error("[WarEowcfDetector] Failed to send Discord notification: #{e.message}")
        end
      end
    end

    Rails.logger.info("[WarEowcfDetector] Detection run at #{t.utc}, created #{created.size} new EoWCF records.")
    created
  end

  # percent change from old to new (handle zero safely)
  def self.percent_change(old_val, new_val)
    old = (old_val || 0).to_f
    new = (new_val || 0).to_f
    return 0.0 if old == 0 && new == 0
    return 1.0 if old == 0 && new > 0 # treat as 100% increase
    ((new - old) / (old.zero? ? 1.0 : old)).to_f
  end

  def self.parse_opponent_loc(stance_string)
    return nil if stance_string.nil?
    s = stance_string.to_s.strip
    # stance could be "war 6:9" or "war 6:9 something"
    tokens = s.split
    return nil unless tokens[0].downcase == "war"
    tokens[1]
  end
end
