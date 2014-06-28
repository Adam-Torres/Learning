#Hello World test app using ruby Sinatra
require "rubygems"
require "sinatra"
require "haml"
require "sinatra/content_for"

get "/" do
	@db_event_hash = {
		"12345" => "BlueMix Workshop Dallas IIC ",
		"67890" => "BlueMix Workshop Waltham IIC ",
		"25793" => "BlueMix Workshop La Gaude IIC "
	}
	haml :select_event_feed_back
end