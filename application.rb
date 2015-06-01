require "sinatra"
require "instagram"

enable :sessions

CALLBACK_URL = "http://localhost:4567/oauth/callback"

Instagram.configure do |config|
  config.client_id = "ba0bd1f9f30d409b883178020f86eb69"
  config.client_secret = "8e0a859e70c44b7898b7f5adb3f91e50"
end

get "/" do
  '<h1>InstaContest</h1><a href="/oauth/connect">Connect with Instagram</a>'
end

get "/oauth/connect" do
  redirect Instagram.authorize_url(:redirect_uri => CALLBACK_URL)
end

get "/oauth/callback" do
  response = Instagram.get_access_token(params[:code], :redirect_uri => CALLBACK_URL)
  session[:access_token] = response.access_token
  redirect "http://linc11.stage.lithium.com/t5/InstaContest/con-p/Instacontest"
end
