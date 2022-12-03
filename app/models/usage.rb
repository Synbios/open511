class Usage < ApplicationRecord

  SEARCH_REQUEST = "search"
  CREATE_REQUEST = "create"

  SUCCESS_STATUS = "ok"
  FAILED_STATUS = "bad"

  def Usage.record_request(request_type, ip, status)
    Usage.create request_type: request_type, ip: ip, status: status
  end
end
