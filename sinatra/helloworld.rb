#Hello World test app using ruby Sinatra
require "rubygems"
require "sinatra"
require "haml"
require "sinatra/content_for"
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
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
		"55657" => "BlueMix Workshop x IIC"
	}
	haml :select_event_feed_back
end
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
post '/generate_fb_report' do
#get the selection from list
	this_event_id=params[:event_id]
	"this is your value: #{this_event_id}, first value is: #{this_event_id[0]},second value is: #{this_event_id[1]}"

#	"This is your value: #{event_id[0]} "
#	haml :index
end


=begin
#=-=-=-=-=-=-=-Do This on button click-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=
post '/generate_fb_report' do
  session!
  messages=""
  if usaEdition == 1
    table_name ="BX.SURVEY"
    messages="FEEDBACK_ID, EVENT_ID, COMPANY_NAME, COMPANY_TYPE, IMPRESSION, WILLUSEBLUEMIX, IMPORTANTSERVICES, PUBLISHSERVICE, PUBLISHSERVICEREASON, COMMENTS, METNEEDS, NOTMETNEEDS, WORKSHOP_RATING, CONTENT_RATING, DEMOS_RATING, LABS_RATING, PRESENTER_RATING\n"
  else
    table_name ="BX.FEEDBACK"
    messages="EVENT_ID, Name, COMPANY_NAME , COMPANY_TYPE , EMAIL , PHONE , JOB_ROLE , WORKSHOP_RATING , CONTENT_RATING , DEMOS_RATING , LABS_RATING , PRESENTER_RATING , NEEDS_MET , NEEDS_NOT_MET_REASONS , CONSIDER_BLUEMIX , WHEN_TO_USE_BLUEMIX , USE_BLUEMIX_PURPOSE , ALLOW_CONTACT , CONTACT_NAME , CONTACT_NUM , FUTURE_FOLLOWUP , OTHER_COMMENTS , PUBLISH_OPT_OUT\n"
 
  end 
  this_event_id=params[:event_id]
  total = String.new
  sql_output_hash = Hash.new []  
  
  
  sql = "SELECT * FROM #{table_name} WHERE EVENT_ID ='#{this_event_id}';"
  if stmt=IBM_DB.exec(conn, sql)
    total = total + sql + "<BR><BR>\n"
    out = "Statement execution successful!"
    total=total + out + "<BR><BR>\n"

    while row = IBM_DB.fetch_assoc(stmt)
      row.each do |key,value|
        messages += "#{row[key]}"
        messages +=","
        total += " #{row[key]} "
      end
      messages += "\n"
    end
    # free the resources associated with the result set
    IBM_DB.free_result(stmt)
  end
  
  content_type 'application/csv'
  attachment "#{this_event_id}.csv"
  response.write(messages) 
end
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
=end

