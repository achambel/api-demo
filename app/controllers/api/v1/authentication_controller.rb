require 'net/http'

module Api::V1
  class AuthenticationController < ApiController
    before_action :authorize_request, except: [:login, :auth_google]

    # POST /auth/login
    def login
      @user = User.find_by_email(params[:email])
      if @user&.authenticate(params[:password])
        token = JsonWebToken.encode(user_id: @user.id)
        render json: { token: token }
      else
        render json: { error: 'unauthorized' }, status: :unauthorized
      end
    end

    # POST /auth/google
    def auth_google
      logger.info 'Verifying google token...'
      token_endpoint = "https://oauth2.googleapis.com/tokeninfo?id_token=" + params[:provider_token]
      logger.info "Trying to connect to #{token_endpoint}"
      uri = URI(token_endpoint)
      response = Net::HTTP.get_response(uri)
      if response.code.starts_with? '2' # success family 2xx
        # todo parse json
        @google_account = JSON.parse(response.body)
        @user = User.find_by_email(@google_account[:email])
        if @user
          # todo: update user info from google fields
        else
          @rand_pwd = SecureRandom.alphanumeric(40)
          @user = User.new(
            name: @google_account['name'],
            email: @google_account['email'],
            username: @google_account['email'],
            password: BCrypt::Password.create(@rand_pwd)
            )
          byebug
          if @user.save
            render json: @user
          else
            render json: { errors: @user.errors.full_messages },
              status: :unprocessable_entity
          end
        end

      else
        logger.info 'Google Token verification has failed'
        logger.info "Response code: " + response.code
        logger.info "Response body: " + response.body
        render json: { error: 'unauthorized' }, status: :unauthorized
      end
    end

  end
end