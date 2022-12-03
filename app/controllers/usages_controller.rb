include ActionView::Helpers::DateHelper

class UsagesController < ActionController::API

  def index
    render json: {
      search_calls: Usage.where(request_type: Usage::SEARCH_REQUEST, status: Usage::SUCCESS_STATUS).count,
      create_calls: Usage.where(request_type: Usage::CREATE_REQUEST, status: Usage::SUCCESS_STATUS).count,
      updated_at: time_ago_in_words(Time.now)
    }
  end
end
