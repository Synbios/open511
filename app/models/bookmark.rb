require 'uri'
require 'net/http'

class Bookmark < ApplicationRecord
  belongs_to :user

  after_create :load_data

  # download data from API
  def load_data
    uri = URI("https://api.open511.gov.bc.ca/events/#{self.event_id}")
    res = Net::HTTP.get_response(uri)
    if res.code == "200"
      obj = JSON.parse res.body
      self.update data: obj["events"].first.to_json
    end
  end
end
