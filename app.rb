require 'sinatra/base'
require 'rack-flash'
require 'slim'
require 'sass'
require 'twitter'
require 'omniauth-twitter'
require 'dotenv'
require 'sinatra/reloader' if development?
require_relative 'lib/twitter_controller'
require_relative 'helpers/application_helper'

Dotenv.load

class Server < Sinatra::Base
  configure do
    use Rack::Session::Cookie, key: 'rack.session',
                               expire_after: 1200,
                               secret: Digest::SHA256.hexdigest(rand.to_s)
    use Rack::Flash
    use OmniAuth::Builder do
      provider :twitter, ENV["TWITTER_API_KEY"], ENV["TWITTER_API_SECRET"]
    end
  end

  helpers ApplicationHelper

  get '/' do
    if signed_in?
      slim :index
    else
      slim :sign_in
    end
  end

  post '/delete_tweets' do
    header = params['header']
    count = params['count'].to_i

    if !signed_in? || header.empty? || count < 1
      flash[:error] = "ツイートの削除に失敗しました"
      redirect '/'
    end

    twitter_controller = TwitterController.new(current_users_twitter_client)
    twitter_controller.delete_recent_tweets_if(count: count) do |t|
      t.text.start_with?(header)
    end

    flash[:notice] = "ツイートの削除に成功しました"
    redirect '/'
  end

  get '/auth/twitter/callback' do
    auth = request.env['omniauth.auth']

    session[:screen_name] = auth[:info][:nickname]
    session[:twitter_oauth] = auth[:credentials]

    flash[:notice] = "ログインしました"
    redirect '/'
  end
end