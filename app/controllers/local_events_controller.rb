class LocalEventsController < ActionController::API

  # return highest severity events by area id
  # usage example:
  # curl -H "email: youz3@ualberta.ca" -H "password: 123"  'http://0.0.0.0:3000/local_events?limit=1&area_id=drivebc.ca%2F3'
  def index
    limit = params[:limit].present? ? params[:limit].to_i : 10
    offset = params[:offset].present? ? params[:offset].to_i : 0
    area_id = params[:area_id]
    user = User.find_by email: request.headers["email"]
    begin
      if user.nil?
        raise Exception.new("Email does not exist")
      end
      if !user.valid_password?(request.headers["password"])
        raise Exception.new("Incorrect password")
      end
      if limit <= 0 || limit > 500
        raise Exception.new("Limit must between 1-500")
      end
      if offset < 0
        raise Exception.new("Offset must be non-negative")
      end
      if area_id.blank?
        raise Exception.new("Must specify an area id")
      end

      area = Area.find_by api_id: params[:area_id]
      if area.present?
        bookmarks = area.bookmarks.order(severity_level: :asc).offset(offset).limit(limit)
        total = bookmarks.count
        data = bookmarks.to_a.map{|bookmark| JSON.parse(bookmark.data)}
      else
        total = 0
        data = []
      end
      user.add_search_usage_record request.remote_ip, Usage::SUCCESS_STATUS
      pagination = {
        total: total,
        offset: offset,
        limit: limit,
        has_more: offset+limit < total
      }

      render json: {status: :ok, events: data, pagination: pagination}
    rescue Exception => e
      #logger.debug e.backtrace.join("\n")
      if user.present?
        user.add_search_usage_record request.remote_ip, Usage::FAILED_STATUS
      end

      render json: {status: :error, message: e.message}
    end
  end

  # this allows users create a local saved event
  #  usage example
  # curl -X POST 'http://0.0.0.0:3000/local_events' -H "email: youz3@ualberta.ca" -H "password: 123" -H "Content-Type: application/json" -d '{"event": {"jurisdiction_url":"https://api.open511.gov.bc.ca/jurisdiction","url":"https://api.open511.gov.bc.ca/events/drivebc.ca/DBC-28953","id":"drivebc.ca/DBC-28953","headline":"CONSTRUCTION","status":"ACTIVE","created":"2021-05-07T17:31:08-07:00","updated":"2022-12-01T20:14:39-08:00","description":"Highway 1, in both directions. Construction work between Columbia West FSR and Wiseman Rd for 8.1 km (18 to 10 km east of East Boundary of Glacier National Park). Until Thu Nov 23, 2023. Watch for traffic control. Expect minor delays. Construction traffic zone. Obey all traffic signs. Last updated Thu Dec 1 at 8:14 PM MST. (DBC-28953)","+ivr_message":"Highway 1, in both directions. Construction work between Columbia West FSR and Wiseman Rd for 8.1 km (18 to 10 km east of East Boundary of Glacier National Park). Until Thursday, November 23. Watch for traffic control. Expect minor delays. Construction traffic zone. Obey all traffic signs. Last updated Thursday, December 1 at 8:14 PM.","+linear_reference_km":941.22,"schedule":{"intervals":["2021-05-08T00:31/2023-11-24T07:59"]},"event_type":"CONSTRUCTION","event_subtypes":["ROAD_MAINTENANCE"],"severity":"MINOR","geography":{"type":"LineString","coordinates":[[-117.401688,51.495589],[-117.400044,51.494627],[-117.398994,51.494012],[-117.398965,51.493996],[-117.397434,51.493152],[-117.396474,51.492685],[-117.395246,51.492147],[-117.394782,51.49196],[-117.39394,51.491621],[-117.389217,51.489718],[-117.387099,51.488864],[-117.384263,51.487721],[-117.367755,51.481064],[-117.364974,51.479942],[-117.363456,51.479331],[-117.363271,51.479257],[-117.362033,51.478759],[-117.361787,51.478676],[-117.361343,51.478526],[-117.360625,51.478385],[-117.360008,51.47832],[-117.359402,51.478314],[-117.358994,51.478351],[-117.358862,51.478363],[-117.35825,51.478469],[-117.357721,51.478627],[-117.357277,51.478814],[-117.357039,51.478915],[-117.356972,51.478943],[-117.356945,51.478954],[-117.356877,51.478983],[-117.356378,51.479195],[-117.355538,51.479551],[-117.355027,51.479737],[-117.354603,51.479892],[-117.35359,51.480185],[-117.351608,51.480673],[-117.350158,51.481031],[-117.35006,51.481055],[-117.350044,51.481059],[-117.346246,51.481983],[-117.339476,51.483631],[-117.338988,51.48375],[-117.335835,51.484517],[-117.335504,51.484598],[-117.335082,51.484698],[-117.334455,51.484847],[-117.331003,51.48572],[-117.329858,51.48601],[-117.329102,51.486201],[-117.328802,51.486277],[-117.328424,51.48637],[-117.323425,51.487591],[-117.319124,51.488642],[-117.317358,51.489074],[-117.316437,51.4893],[-117.310362,51.490789],[-117.309007,51.49112],[-117.308706,51.491194],[-117.305068,51.492085],[-117.303864,51.49238],[-117.303248,51.492532],[-117.299196,51.493526]]},"roads":[{"name":"Highway 1","from":"Columbia West FSR","to":"Wiseman Rd","direction":"BOTH"}],"areas":[{"url":"http://www.geonames.org/8630135","name":"Rocky Mountain District","id":"drivebc.ca/3"}]}}'


  def create
    user = User.find_by email: request.headers["email"]
    begin
      if user.nil?
        raise Exception.new("Email does not exist")
      end
      if !user.valid_password?(request.headers["password"])
        raise Exception.new("Incorrect password")
      end

      if params[:event].blank?
        raise Exception.new("Missing required parameter: event")
      eslif params[:event][:id].blank?
        raise Exception.new("Missing required parameter: id")
      elsif user.bookmarks.where(event_id: params[:event][:id]).count > 0
        raise Exception.new("#{params[:event][:id]} aleady exists")
      elsif params[:event][:jurisdiction_url].blank?
        raise Exception.new("Missing required nested parameter: jurisdiction_url")
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

      bookmark = user.bookmarks.new event_id: params[:event][:id], data: params[:event].to_json
      unless bookmark.save
        raise Exception.new("Failed to save event.")
      end
      bookmark.assign_area_and_severity params[:event]

      user.add_create_usage_record request.remote_ip, Usage::SUCCESS_STATUS

      render json: {status: :ok, local_id: bookmark.id, event_id: bookmark.event_id}, status: :created
    rescue Exception => e
      user.add_create_usage_record request.remote_ip, Usage::FAILED_STATUS

      render json: {status: :error, message: e.message}
    end

  end
end
