# app/models/eowcf_record.rb
class EowcfRecord < ApplicationRecord
  belongs_to :kingdom, optional: true

  validates :eowcf_start, :eowcf_end, presence: true

  def ticks_remaining(reference_time = Time.current)
    # ticks are hours; return integer hours remaining (can be negative)
    ((eowcf_end - reference_time) / 1.hour).floor
  end
end