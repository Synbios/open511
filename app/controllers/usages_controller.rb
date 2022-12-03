include ActionView::Helpers::DateHelper

class UsagesController < ApplicationController

  def index
    if current_user.present?
      render json: {
        search_calls: current_user.usages.where(request_type: Usage::SEARCH_REQUEST, status: Usage::SUCCESS_STATUS).count,
        create_calls: current_user.usages.where(request_type: Usage::CREATE_REQUEST, status: Usage::SUCCESS_STATUS).count,
        updated_at: time_ago_in_words(Time.now)
      }
    else
      render json: {
        search_calls: 0,
        create_calls: 0,
        updated_at: "Error: user not signed in"
      }
    end
  end
end
