require 'uri'
require 'net/http'

class Bookmark < ApplicationRecord
  has_and_belongs_to_many :areas
  belongs_to :user

  after_create :load_data

  # major > moderate > minor > unknown
  SEVERITY_ORDER = {
    MAJOR: 1,
    MODERATE: 2,
    MINOR: 3,
    UNKNOWN: 4
  }

  # download data from API
  # this will also create assign area and severity (for local API queries)
  def load_data(forced=false)
    if self.data.nil? || forced
      uri = URI("https://api.open511.gov.bc.ca/events/#{self.event_id}")
      res = Net::HTTP.get_response(uri)
      if res.code == "200"
        obj = JSON.parse res.body
        event = obj["events"].first
        self.update data: event.to_json

        assign_area_and_severity event
      end
    end
  end

  def assign_area_and_severity(event)
    # add area
    self.areas = event["areas"].map do |area_obj|
      area = Area.find_or_create_by api_id: area_obj["id"]
      if area.name.blank?
        area.update name: area_obj["name"]
      end
      area
    end

    # add severity
    self.update severity_level: SEVERITY_ORDER[event["severity"].to_sym]
  end
end
