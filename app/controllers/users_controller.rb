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

  def create_new
    email = params[:user][:email]
    if email.blank?
      @error = "Please enter an email"
    elsif User.where(email: email).exists?
      @error = "This email already exists"
    else
      @user = User.new email: email, password: params[:user][:password], password_confirmation: params[:user][:password_confirmation]
      logger.info ">>>>>>> 1"
      if @user.save
        logger.info ">>>>>>> 2"
        sign_in @user
      else
        logger.info ">>>>>>> 3"
        @error = @user.errors.full_messages.join(", ")
        @error = "Email already exists" if @error.blank?
      end
    end
  end



end
