require "sinatra"
require "instagram"
require "active_record"
require 'yaml'
require "active_record"

enable :sessions

CALLBACK_URL = "http://localhost:4567/oauth/callback"

database_config_file = File.join(File.dirname(File.expand_path(__FILE__)), 'config', 'database.yml')
config_file = File.join(File.dirname(File.expand_path(__FILE__)), 'config', 'config.yml')

config = File.exists?(config_file) ? YAML::load_file(config_file) : {}
database_config = File.exists?(database_config_file) ? YAML::load(ERB.new(File.read(database_config_file)).result)["production"] : config["database"]
ActiveRecord::Base.establish_connection(database_config)

Instagram.configure do |insta_config|
  insta_config.client_id = config['instagram']['client_id']
  insta_config.client_secret = config['instagram']['client_secret']
end

class User < ActiveRecord::Base
  validates_presence_of :lithium_id, :instagram_username, :instagram_token
end

get "/" do
  '<h1>InstaContest</h1><a href="/oauth/connect?lithium_id=84">Connect with Instagram</a>'
end

get "/oauth/connect" do
  redirect Instagram.authorize_url(:redirect_uri => CALLBACK_URL, :state => params['lithium_id'])
end

get "/oauth/callback" do
  response = Instagram.get_access_token(params[:code], :redirect_uri => CALLBACK_URL)

  user = User.new(:lithium_id => params[:state], :instagram_token => response.access_token, :instagram_username => response.user.username)

  if user.save
    redirect "http://linc11.stage.lithium.com/t5/InstaContest/con-p/Instacontest"
  else
    "<h1>Error !</h1><p>We're unable to link your lithium account and your instagram account.</p><p>#{user.errors.messages.inspect}</p>"
  end
end
