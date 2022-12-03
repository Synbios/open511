require 'uri'
require 'net/http'

# deprecated: this code is not used. I misundertood the API storage end.
class EventsController < ActionController::API

  QUERY_SIZE = 100
  QUERY_URI = "https://api.open511.gov.bc.ca/events"

  # return highest severity events by area id
  def index
    limit = params[:limit].present? ? params[:limit].to_i : 10
    offset = params[:offset].present? ? params[:offset].to_i : 0
    area_id = params[:area_id]
    begin
      if limit <= 0 || limit > 500
        raise Exception.new("Limit must between 1-500")
      end
      if offset < 0
        raise Exception.new("Offset must be non-negative")
      end
      if area_id.blank?
        raise Exception.new("Must specify an area id")
      end

      # step 1: get all events of that area
      events = query_remote_events(0, QUERY_SIZE, area_id)

      # step 2: sort events by severity
      events.sort! { |a,b| Bookmark::SEVERITY_ORDER[a["severity"].to_sym] <=> Bookmark::SEVERITY_ORDER[b["severity"].to_sym] }.map{|x| x["severity"]}

      # step 3: return the request amount of events
      results = events[offset, offset+limit]
      results = results.nil? ? [] : results

      render json: {status: :ok, events: results, has_more: offset+limit < events.length}
    rescue Exception => e

      render json: {status: :error, message: e.message}
    end
  end

  # this allows users create a local event (because the official API docs has no create event API)
  # usage:
  # curl -d '{"event":{"url": "/events/drivebc.ca/153307", "jurisdiction": "/jurisdiction", "headline":"abc", "status": "active", "event_type": "INCIDENT", "seve "geography":"stringfied hash","schedule":"stringfied hash"}}' -H "Content-Type: application/json" -X POST http://0.0.0.0:3000/events
  def create
    begin
      if params[:event].blank?
        raise Exception.new("Missing required parameter: event")
      elsif params[:event][:jurisdiction].blank?
        raise Exception.new("Missing required nested parameter: jurisdiction")
      elsif params[:event][:url].blank?
        raise Exception.new("Missing required nested parameter: url")
      elsif params[:event][:status].blank?
        raise Exception.new("Missing required nested parameter: status")
      elsif params[:event][:headline].blank?
        raise Exception.new("Missing required nested parameter: headline")
      elsif params[:event][:event_type].blank?
        raise Exception.new("Missing required nested parameter: event_type")
      elsif params[:event][:severity].blank?
        raise Exception.new("Missing required nested parameter: severity")
      elsif params[:event][:geography].blank?
        raise Exception.new("Missing required nested parameter: geography")
      elsif params[:event][:schedule].blank?
        raise Exception.new("Missing required nested parameter: schedule")
      end

      event = Event.new event_params
      unless event.save
        raise Exception.new("Failed to save event.")
      end

      render json: {status: :ok}, status: :created
    rescue Exception => e

      render json: {status: :error, message: e.message}
    end

  end

  private
  def query_remote_events(offset, limit, area_id)
    uri = URI(QUERY_URI)
    params = { area_id: area_id, offset: offset, limit: limit }
    uri.query = URI.encode_www_form(params)
    res = Net::HTTP.get_response(uri)

    if res.code == "200"
      events = JSON.parse(res.body)["events"]
      if events.length == limit
        events + query_remote_events(offset+limit, limit, area_id)
      else
        events
      end
    else
      raise Exception.new("An error happened when query remote API")
    end
  end

  def event_params
    params.require(:event).permit(
      :url, :jurisdiction_url, :headline, :status, :description, :ivr_message,
      :schedule, :event_type, :event_subtypes, :severity, :geography, :roads,
      :areas
    )
  end
end
