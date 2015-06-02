require "instagram"
require "active_record"
require "awesome_print"
require 'yaml'
require './lithium_api.rb'
require 'open-uri'

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

def check_media(media_item, hash_tag)
	if media_item.type == 'image' and media_item.caption.to_s.include? hashtag
		return true
	end
	return false
end


# check hashtagged media for each user

lithium_client = Lithium.new
lithium_client.get_session_key

User.all.each do |user|
  client = Instagram.client(:access_token => user.instagram_token)
  client.user_media_feed.each do |media|
    if media.type == 'image' && media.caption.to_s.include?("#hausguest")

      file = File.open("temp.jpg", "w") do |f|
        f.write open(media['images']['standard_resolution']['url']).read
      end

      image_response = lithium_client.multipart_request(user.lithium_id, "/users/id/#{user.lithium_id}/media/albums/default/public/images/upload", {"image.content" => File.new("temp.jpg", "rb")})
      ap image_response

      response = lithium_client.request("/boards/id/Instacontest/messages/post", :post, {"message.subject" => media.caption.text.to_s, "message.author" => "id/#{user.lithium_id}", "message.body" => "<img data-image-uid=\"#{image_response["image"]["id"]["$"]}\" data-viewable-img=\"true\" id=\"display_0\" src=\"#{image_response['image']["url"]["$"]}\">"})
    end
  end

end
