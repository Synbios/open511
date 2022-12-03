class Usage < ApplicationRecord
  belongs_to :user

  SEARCH_REQUEST = "search"
  CREATE_REQUEST = "create"

  SUCCESS_STATUS = "ok"
  FAILED_STATUS = "bad"
end
