Rails.application.routes.draw do
  constraints subdomain: 'api' do
    scope module: 'api' do
      namespace :v1 do
        resources :users
        post '/auth/login', to: 'authentication#login'
        post '/auth/google', to: 'authentication#auth_google'
        get '/*a', to: 'application#not_found'
      end
    end
  end
end
