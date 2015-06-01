require 'rubygems'
require 'yaml'
require "active_record"

database_config_file = File.join(File.dirname(File.expand_path(__dir__)), 'config', 'database.yml')
config_file = File.join(File.dirname(File.expand_path(__dir__)), 'config', 'config.yml')

config = File.exists?(config_file) ? YAML::load_file(config_file) : {}
database_config = File.exists?(database_config_file) ? YAML::load(ERB.new(File.read(database_config_file)).result)["production"] : config["database"]
ActiveRecord::Base.establish_connection(database_config)

ActiveRecord::Schema.define(:version => 201506012326) do
  create_table "users", :force => true do |t|
    t.string "lithium_id"
    t.string "instagram_username"
    t.string "instagram_token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
end
