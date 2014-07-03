#Hello World test app using ruby Sinatra
require "rubygems"
require "sinatra"
require "haml"
require "sinatra/content_for"

get "/" do
	@db_event_hash = {
		"12345" => "BlueMix Workshop Dallas IIC ",
		"67890" => "BlueMix Workshop Waltham IIC ",
		"25793" => "BlueMix Workshop La Gaude IIC ",
		"83657" => "BlueMix Workshop x IIC",
		"93657" => "BlueMix Workshop x IIC",
		"03657" => "BlueMix Workshop x IIC",
		"23657" => "BlueMix Workshop x IIC",
		"33657" => "BlueMix Workshop x IIC",
		"43657" => "BlueMix Workshop x IIC",
		"53657" => "BlueMix Workshop x IIC",
		"63657" => "BlueMix Workshop x IIC",
		"73657" => "BlueMix Workshop x IIC",
		"13657" => "BlueMix Workshop x IIC",
		"33657" => "BlueMix Workshop x IIC",
		"55657" => "BlueMix Workshop x IIC",
	}
	haml :select_event_feed_back
end