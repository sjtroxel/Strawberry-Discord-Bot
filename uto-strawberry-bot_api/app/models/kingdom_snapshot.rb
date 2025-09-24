# app/models/kingdom_snapshot.rb
class KingdomSnapshot < ApplicationRecord
  belongs_to :kingdom, optional: true

  # quick helpers
  def provinces_array
    self.provinces || []
  end
end