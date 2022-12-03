class BookmarksController < ApplicationController
  before_action :check_authentication, except: [:check]

  NA = '<i class="text-muted">N/A</i>'

  def index
    @bookmarks = current_user.bookmarks.where.not(data: nil)
    logger.info render_to_string("index")
  end

  def create
    @bookmark = current_user.bookmarks.find_or_initialize_by event_id: params[:event_id]
    @bookmark.save
  end

  def destroy
    @bookmark = current_user.bookmarks.find_by id: params[:id]
    if @bookmark.present?
      @bookmark.destroy
    end
  end

  # check if the given listing of event ids are bookmarked
  def check
    map = {}
    if current_user.present?
      current_user.bookmarks.where(event_id: params[:event_ids]).each do |bookmark|
        map[bookmark.event_id] = bookmark.id
      end
    end
    render json: map
  end

  private
  def check_authentication
    if current_user.nil?
      render js: "window.location.href='/sign_in';"
    end
  end
end
