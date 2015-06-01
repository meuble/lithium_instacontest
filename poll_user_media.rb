require "instagram"
require "active_record"
require 'yaml'

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


# function that returns hashtagged_media when it exists

def get_user_recent_hashtagged_media(user, hashtags)
  client = Instagram.client(:access_token => user.instagram_token)
  user = client.user
  hashtagged_media = [];
  new_max_id = user.instagram_max_id
  client.user_recent_media(:max_id => user.instagram_max_id) do |media_item|
  	#new_max_id = user.instagram_max_id == nil or media_item.id > new_max_id ? media_item.id : new_max_id
  	hashtags.each do |hashtag|
  		print hash_tag
    	if check_media(media_item, hashtag)
      		hashtagged_media << media_item
      	end
    end
  end
  user.instagram_max_id = new_max_id;
  user.save
  return hashtagged_media
end

def check_media(media_item, hash_tag)
	if media_item.type == 'image' and media_item.caption.to_s.include? hashtag
		return true
	end
	return false
end


# check hashtagged media for each user

User.all.each do |user|
  print user
  #the code here is called once for each user
  # user is accessible by 'user' variable
  hashtags = ['#provo','#lithium'];
  media_item = get_user_recent_hashtagged_media(user, hashtags)
  if media_item == nil
  	print "NOT FOUND"
  else 
  	print media_item
  end
end
