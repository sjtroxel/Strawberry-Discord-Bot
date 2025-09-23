class Kingdom < ApplicationRecord
    has_many :provinces, dependent: :destroy
end
