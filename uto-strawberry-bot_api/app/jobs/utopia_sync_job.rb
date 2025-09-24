# app/jobs/utopia_sync_job.rb
class UtopiaSyncJob < ApplicationJob
  queue_as :default

  def perform
    timestamp = UtopiaFetcher.sync!   # returns timestamp string from dumped data (or nil)
    # Save snapshots based on current DB state (use timestamp if available)
    UtopiaSnapshotter.save_snapshots!(timestamp || Time.current)

    # Run the detection process using the same timestamp
    WarEowcfDetector.run!(timestamp || Time.current)

    Rails.logger.info "[UtopiaSyncJob] Successfully synced & ran detection at #{Time.current}"
  rescue => e
    Rails.logger.error "[UtopiaSyncJob] Error during sync/detect: #{e.class} #{e.message}\n#{e.backtrace.first(6).join("\n")}"
    raise e
  end
end