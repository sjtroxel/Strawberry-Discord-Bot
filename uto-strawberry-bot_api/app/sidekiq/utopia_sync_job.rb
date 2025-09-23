# app/jobs/utopia_sync_job.rb
class UtopiaSyncJob < ApplicationJob
  queue_as :default

  def perform
    UtopiaFetcher.sync!
    Rails.logger.info "[UtopiaSyncJob] Successfully synced kingdoms and provinces at #{Time.current}"
  rescue => e
    Rails.logger.error "[UtopiaSyncJob] Error during sync: #{e.message}"
  end
end
