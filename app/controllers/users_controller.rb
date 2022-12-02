class UsersController < ActionController::Base
  layout "application"

  def sign_in_view
    @user = User.new
  end

  def sign_up_view
    @user = User.new
  end

  def delete_session
    sign_out current_user
    redirect_to root_path
  end

  def create_session
    email = params[:user][:email]
    @user = User.find_by email: email
    if email.blank?
      @error = "Please enter an email"
    elsif @user.nil?
      @error = "This email is not registered"
    elsif !@user.valid_password?(params[:user][:password])
      @error = "Password is incorrect"
    else
      sign_in @user
    end
  end

  def create
    email = params[:user][:email]
    if email.blank?
      @error = "Please enter an email"
    elsif User.where(email: email).exists?
      @error = "This email already exists"
    else
      @user = User.new email: email, password: params[:user][:password], password_confirmation: params[:user][:password_confirmation]
      if @user.save
        sign_in @user
      else
        @error = @user.errors.full_messages.join(", ")
      end
    end
  end



end
