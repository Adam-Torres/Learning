# AdminPortal v1.0   Felix Fong                 26/05/2014   Initial release 
# AdminPortal v2.0   Felix Fong & Calvin Bui    03/06/2014   Stable release
# AdminPortal v2.1   Felix Fong & Calvin Bui    05/06/2014   Updated to be compitable with US customized FBF 
# AdminPortal v2.2   Felix Fong & Calvin Bui    06/06/2014   Added show current logged user and ability to allow user change password 
# AdminPortal v2.3   Felix Fong                 07/06/2014   Added initial_setup variable to assist rollout  
 
require 'rubygems'
require 'ibm_db'
require 'sinatra'
require 'json'
require 'haml' # template engine
require 'sinatra/session' # session extension
require 'sinatra/content_for' # use of 'content for' within HAML
require 'digest/md5'
require 'csv'

initial_setup = 0   # 1 is yes , 0 for no 
usaEdition = 1      # USA's feedback form has different table name 
useLocalDB = 0      # 0 for local db, 1 for Bluemix DB 

debug = 0           # debug the sql queries
thisUserID=""       # stores current session USER_ID 
 
if useLocalDB == 1   # use local DB2 variables 
  host = "172.23.123.90"
  #host="localhost"
  database = "bluemix"
  username ="bluemix"
  password = "q1w2e3r4t5"
  db2_port = 50000
  dsn = "DRIVER={IBM DB2 ODBC DRIVER};DATABASE="+database+";HOSTNAME="+host+";PORT="+db2_port.to_s()+";PROTOCOL=TCPIP;UID="+username+";PWD="+password+";"
  conn = IBM_DB.connect(dsn, '', '')
else # BlueMix database variables 
  app_port = ENV['VCAP_APP_PORT']
  parsed = JSON.parse(ENV['VCAP_APPLICATION'])
  servicename = "SQLDB-1.0"
  url  = parsed["application_uris"]
  jsondb_db = JSON.parse(ENV['VCAP_SERVICES'])[servicename]
  credentials = jsondb_db.first["credentials"]
  host = credentials["host"]
  username = credentials["username"]
  password = credentials["password"]
  database = credentials["db"]
  db2_port = credentials["port"]
  dsn = "DRIVER={IBM DB2 ODBC DRIVER};DATABASE="+database+";HOSTNAME="+host+";PORT="+db2_port.to_s()+";PROTOCOL=TCPIP;UID="+username+";PWD="+password+";"
  conn = IBM_DB.connect(dsn, '', '')
end

# session secrets
set :session_fail, '/login'
set :session_secret, 'So0perSeKr3t!'
set :session_expire, 1200

get '/' do
  session!
  haml :index
end

get '/login' do
  haml :login
end

post '/login' do
  email = params[:email]
  userpassword = params[:password]
  stmt = IBM_DB.exec(conn, "SELECT COUNT(*) from BX.USER WHERE USER_ID = '#{email}' AND DECRYPT_CHAR(PASSWORD,'#{email}') = '#{userpassword}' AND STATUS = 'Y'")
  IBM_DB.fetch_row(stmt)

  if IBM_DB.result(stmt, 0) == 1
    session_start!
    if stmt = IBM_DB.exec(conn, "SELECT USER_ID, USER_NAME, COUNTRY, ROLE from BX.USER WHERE USER_ID = '#{email}'")
      while row = IBM_DB.fetch_assoc(stmt)
        session[:usertype] = row['ROLE']
        session[:usercountry] = row['COUNTRY']
        session[:username] = row['USER_NAME']
        thisUserID=row['USER_ID']
      end
    end
    redirect '/'
  else
    redirect '/login'
  end
end

get '/create_table' do
  session!
  haml :create_tables
end

get '/logout' do
  session_end!
  redirect '/'
end

get '/cr_country_table' do
  session!
  tablename = "BX.COUNTRY"
  total = String.new
  out = String.new
  total = total + "Connecting to " + dsn + "<BR><BR>\n"
  if conn = IBM_DB.connect(dsn, '', '')
    sql = "CREATE TABLE " + tablename + " (COUNTRY_CODE CHAR(2) NOT NULL, COUNTRY_TAG SMALLINT NOT NULL, COUNTRY_NAME VARCHAR(50) NOT NULL, STATUS CHAR(1) NOT NULL,PRIMARY KEY (COUNTRY_CODE),UNIQUE (COUNTRY_NAME))"
    if stmt = IBM_DB.exec(conn, sql)
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution successful"
      total = total + out + "<BR>\n"
    else
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution failed: #{IBM_DB.stmt_errormsg}"
      total = total + out + "<BR>\n"
    end
  else
    out = "Connection failed: #{IBM_DB.conn_errormsg}"
    total = total + out + "<BR><BR>\n"
  end # connect
  #total += "<a href=#{url2}/>Return to homepage </a></div></body>"
  total  # display messages
end  # get

get '/cr_city_table' do
  session!
  tablename = "BX.CITY"
  total = String.new
  out = String.new
  total = total + "Connecting to " + dsn + "<BR><BR>\n"
  if conn = IBM_DB.connect(dsn, '', '')
    sql = "CREATE TABLE " + tablename + " (CITY_CODE CHAR(3) NOT NULL, CITY_NAME VARCHAR(50) NOT NULL, STATE_NAME VARCHAR(50), COUNTRY_NAME VARCHAR(50) NOT NULL, STATUS CHAR(1) NOT NULL, PRIMARY KEY(CITY_CODE),FOREIGN KEY (COUNTRY_NAME) references BX.COUNTRY (COUNTRY_NAME))"

    if stmt = IBM_DB.exec(conn, sql)
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution successful"
      total = total + out + "<BR>\n"
    else
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution failed: #{IBM_DB.stmt_errormsg}"
      total = total + out + "<BR>\n"
    end
  else
    out = "Connection failed: #{IBM_DB.conn_errormsg}"
    total = total + out + "<BR><BR>\n"
  end # connect
  #total += "<a href=#{url2}/>Return to homepage </a></div></body>"
  total  # display messages
end  # get

get '/cr_event_type_table' do
  session!
  tablename = "BX.EVENT_TYPE"
  total = String.new
  out = String.new
  total = total + "Connecting to " + dsn + "<BR><BR>\n"
  if conn = IBM_DB.connect(dsn, '', '')
    sql = "CREATE TABLE " + tablename + "(EVENT_CODE CHAR(2) NOT NULL, EVENT_CODE_DESC  VARCHAR(100) NOT NULL, PRIMARY KEY(EVENT_CODE) )"

    if stmt = IBM_DB.exec(conn, sql)
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution successful"
      total = total + out + "<BR>\n"
    else
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution failed: #{IBM_DB.stmt_errormsg}"
      total = total + out + "<BR>\n"
    end
  else
    out = "Connection failed: #{IBM_DB.conn_errormsg}"
    total = total + out + "<BR><BR>\n"
  end # connect
  #total += "<a href=#{url2}/>Return to homepage </a></div></body>"
  total  # display messages
end  # get

get '/cr_company_type_table' do
  session!
  tablename = "BX.COMPANY_TYPE"
  total = String.new
  out = String.new
  total = total + "Connecting to " + dsn + "<BR><BR>\n"
  if conn = IBM_DB.connect(dsn, '', '')
    # sql = "CREATE TABLE " + tablename + "( )"
    sql = "CREATE TABLE " + tablename + "(COMPANY_CLASS_ID CHAR(3) NOT NULL, COMPANY_CLASS_DESC VARCHAR(100) NOT NULL, PRIMARY KEY (COMPANY_CLASS_ID) )"

    if stmt = IBM_DB.exec(conn, sql)
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution successful"
      total = total + out + "<BR>\n"
    else
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution failed: #{IBM_DB.stmt_errormsg}"
      total = total + out + "<BR>\n"
    end
  else
    out = "Connection failed: #{IBM_DB.conn_errormsg}"
    total = total + out + "<BR><BR>\n"
  end # connect
  #total += "<a href=#{url2}/>Return to homepage </a></div></body>"
  total  # display messages
end  # get

get '/cr_job_role_table' do
  session!
  tablename = "BX.JOB_ROLE"
  total = String.new
  out = String.new
  total = total + "Connecting to " + dsn + "<BR><BR>\n"
  if conn = IBM_DB.connect(dsn, '', '')
    sql = "CREATE TABLE " + tablename + "(		JOB_ROLE_CODE VARCHAR(15) NOT NULL, JOB_ROLE_DESC VARCHAR(100) NOT NULL, PRIMARY KEY (JOB_ROLE_CODE) )"
    if stmt = IBM_DB.exec(conn, sql)
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution successful"
      total = total + out + "<BR>\n"
    else
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution failed: #{IBM_DB.stmt_errormsg}"
      total = total + out + "<BR>\n"
    end
  else
    out = "Connection failed: #{IBM_DB.conn_errormsg}"
    total = total + out + "<BR><BR>\n"
  end # connect
  #total += "<a href=#{url2}/>Return to homepage </a></div></body>"
  total  # display messages
end  # get

get '/cr_event_table' do
  session!
  tablename = "BX.EVENT"
  total = String.new
  out = String.new
  total = total + "Connecting to " + dsn + "<BR><BR>\n"
  if conn = IBM_DB.connect(dsn, '', '')
    sql = "CREATE TABLE " + tablename + "(EVENT_ID CHAR(17) NOT NULL, EVENT_DESC VARCHAR(100), EVENT_TYPE CHAR(2) NOT NULL, EVENT_COUNTRY CHAR(2) NOT NULL, EVENT_CITY CHAR(3) NOT NULL, 	EVENT_VENUE VARCHAR(100), EVENT_DATE  DATE NOT NULL,EVENT_START_TIME TIME, EVENT_END_TIME TIME, EVENT_MANAGER VARCHAR(100), MANAGER_EMAIL VARCHAR(100), MANAGER_PHONE VARCHAR(25), EVENT_PRESENTER VARCHAR(100), PRESENTER_EMAIL VARCHAR(100), PRESENTER_PHONE VARCHAR(100), EVENT_STATUS CHAR(1) NOT NULL, FBF_STATUS CHAR(1) NOT NULL, EVENT_NOTES VARCHAR(25000),PRIMARY KEY(EVENT_ID) )"

    if stmt = IBM_DB.exec(conn, sql)
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution successful"
      total = total + out + "<BR>\n"
    else
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution failed: #{IBM_DB.stmt_errormsg}"
      total = total + out + "<BR>\n"
    end
  else
    out = "Connection failed: #{IBM_DB.conn_errormsg}"
    total = total + out + "<BR><BR>\n"
  end # connect
  #total += "<a href=#{url2}/>Return to homepage </a></div></body>"
  total  # display messages
end  # get

get '/cr_registration_table' do
  session!
  tablename = "BX.REGISTRATION"
  total = String.new
  out = String.new
  total = total + "Connecting to " + dsn + "<BR><BR>\n"
  if conn = IBM_DB.connect(dsn, '', '')
    sql = "CREATE TABLE " + tablename + "(EVENT_ID CHAR(17) NOT NULL, ATTENDEE_NAME VARCHAR(100) NOT NULL, ATTENDEE_COMPANY VARCHAR(100) NOT NULL, ATTENDEE_EMAIL VARCHAR(100) NOT NULL, ATTENDEE_JOB_ROLE VARCHAR(100) NOT NULL, REGISTRATION_STATUS CHAR(1), ATTENDED_STATUS CHAR(1), REGISTRATION_NOTES VARCHAR(25000), FOREIGN KEY (EVENT_ID) REFERENCES BX.EVENT (EVENT_ID), PRIMARY KEY(EVENT_ID, ATTENDEE_EMAIL) )"
    if stmt = IBM_DB.exec(conn, sql)
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution successful"
      total = total + out + "<BR>\n"
    else
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution failed: #{IBM_DB.stmt_errormsg}"
      total = total + out + "<BR>\n"
    end
  else
    out = "Connection failed: #{IBM_DB.conn_errormsg}"
    total = total + out + "<BR><BR>\n"
  end # connect
  #total += "<a href=#{url2}/>Return to homepage </a></div></body>"
  total  # display messages
end  # get

get '/cr_fbf_table' do
  session!
  tablename = "BX.FEEDBACK"
  total = String.new
  out = String.new
  total = total + "Connecting to " + dsn + "<BR><BR>\n"
  if conn = IBM_DB.connect(dsn, '', '')
    sql = "CREATE TABLE " + tablename + "(EVENT_ID CHAR(17) NOT NULL, Name VARCHAR(100) NOT NULL, COMPANY_NAME VARCHAR(100), COMPANY_TYPE VARCHAR(100), EMAIL VARCHAR(100) NOT NULL, PHONE VARCHAR(50), JOB_ROLE VARCHAR(200), WORKSHOP_RATING INT, CONTENT_RATING INT, DEMOS_RATING INT, LABS_RATING INT, PRESENTER_RATING INT, NEEDS_MET CHAR(1), NEEDS_NOT_MET_REASONS VARCHAR(10000), CONSIDER_BLUEMIX CHAR(1), WHEN_TO_USE_BLUEMIX CHAR(5), USE_BLUEMIX_PURPOSE CHAR(50), ALLOW_CONTACT CHAR(1), CONTACT_NAME VARCHAR(100), CONTACT_NUM VARCHAR(50), FUTURE_FOLLOWUP CHAR(1), OTHER_COMMENTS VARCHAR(10000), PUBLISH_OPT_OUT INT, PRIMARY KEY (EVENT_ID, EMAIL))"
    if stmt = IBM_DB.exec(conn, sql)
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution successful"
      total = total + out + "<BR>\n"
    else
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution failed: #{IBM_DB.stmt_errormsg}"
      total = total + out + "<BR>\n"
    end
  else
    out = "Connection failed: #{IBM_DB.conn_errormsg}"
    total = total + out + "<BR><BR>\n"
  end # connect
  #total += "<a href=#{url2}/>Return to homepage </a></div></body>"
  total  # display messages
end  # get

get '/cr_user_table' do
  session!
  tablename = "BX.USER"
  total = String.new
  out = String.new
  total = total + "Connecting to " + dsn + "<BR><BR>\n"
  if conn = IBM_DB.connect(dsn, '', '')
    sql = "CREATE TABLE " + tablename + "(USER_ID VARCHAR(50) NOT NULL, PASSWORD VARCHAR(100)FOR BIT DATA NOT NULL, USER_NAME CHAR(50) NOT NULL, COUNTRY  VARCHAR(50) NOT NULL,ROLE CHAR(3) NOT NULL, STATUS CHAR(1) NOT NULL,PRIMARY KEY (USER_ID), FOREIGN KEY (COUNTRY) references BX.COUNTRY (COUNTRY_NAME))"
    if stmt = IBM_DB.exec(conn, sql)
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution successful"
      total = total + out + "<BR>\n"
    else
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution failed: #{IBM_DB.stmt_errormsg}"
      total = total + out + "<BR>\n"
    end
  else
    out = "Connection failed: #{IBM_DB.conn_errormsg}"
    total = total + out + "<BR><BR>\n"
  end # connect
  #total += "<a href=#{url2}/>Return to homepage </a></div></body>"
  total  # display messages
end  # get

get '/cr_event_status_table' do
  session!
  tablename = "BX.EVENT_STATUS"
  total = String.new
  out = String.new
  total = total + "Connecting to " + dsn + "<BR><BR>\n"
  if conn = IBM_DB.connect(dsn, '', '')
    sql = "CREATE TABLE " + tablename + "(EVENT_STATUS_CODE CHAR(1) NOT NULL, EVENT_STATUS_DESC VARCHAR(10) NOT NULL, PRIMARY KEY (EVENT_STATUS_CODE))"
    if stmt = IBM_DB.exec(conn, sql)
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution successful"
      total = total + out + "<BR>\n"
    else
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution failed: #{IBM_DB.stmt_errormsg}"
      total = total + out + "<BR>\n"
    end
  else
    out = "Connection failed: #{IBM_DB.conn_errormsg}"
    total = total + out + "<BR><BR>\n"
  end # connect
  total  # display messages
end  # get

get '/cr_fbf_status_table' do
  session!
  tablename = "BX.FBF_STATUS"
  total = String.new
  out = String.new
  total = total + "Connecting to " + dsn + "<BR><BR>\n"
  if conn = IBM_DB.connect(dsn, '', '')
    sql = "CREATE TABLE " + tablename + "(FBF_STATUS_CODE CHAR(1) NOT NULL, FBF_STATUS_DESC VARCHAR(10) NOT NULL, PRIMARY KEY (FBF_STATUS_CODE))"
    if stmt = IBM_DB.exec(conn, sql)
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution successful"
      total = total + out + "<BR>\n"
    else
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution failed: #{IBM_DB.stmt_errormsg}"
      total = total + out + "<BR>\n"
    end
  else
    out = "Connection failed: #{IBM_DB.conn_errormsg}"
    total = total + out + "<BR><BR>\n"
  end # connect
  total  # display messages
end  # get

get '/cr_city_status_table' do
  session!
  tablename = "BX.CITY_STATUS"
  total = String.new
  out = String.new
  total = total + "Connecting to " + dsn + "<BR><BR>\n"
  if conn = IBM_DB.connect(dsn, '', '')
    sql = "CREATE TABLE " + tablename + "(CITY_STATUS_CODE CHAR(1) NOT NULL, CITY_STATUS_DESC VARCHAR(15) NOT NULL, PRIMARY KEY (CITY_STATUS_CODE))"
    if stmt = IBM_DB.exec(conn, sql)
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution successful"
      total = total + out + "<BR>\n"
    else
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution failed: #{IBM_DB.stmt_errormsg}"
      total = total + out + "<BR>\n"
    end
  else
    out = "Connection failed: #{IBM_DB.conn_errormsg}"
    total = total + out + "<BR><BR>\n"
  end # connect
  total  # display messages
end  # get


get '/query' do
  if initial_setup != 1
    session!
  end 
  haml :adhocquery
end

get '/create_event' do
  session!
  sql_append_country = ""
  sql_append_city = ""
  
  if session[:usertype] == "USR" || session[:usertype] == "OPR"  
    sql_append_country = "WHERE COUNTRY_NAME = '#{session[:usercountry]}'"        
    sql_append_city = "AND COUNTRY_NAME = '#{session[:usercountry]}'"         
  end
  @db_country_hash = {}
  
  sql = "SELECT COUNTRY_CODE, COUNTRY_NAME FROM BX.COUNTRY #{sql_append_country}"
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_country_hash["#{row['COUNTRY_NAME']}"]= "#{row['COUNTRY_CODE']}"
    end
  end

  @db_city_hash = {}
  sql = "SELECT CITY_CODE, CITY_NAME FROM BX.CITY WHERE STATUS ='A' #{sql_append_city}"
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_city_hash["#{row['CITY_NAME']}"]= "#{row['CITY_CODE']}"
    end
  end

  @db_evt_type_hash = {}
  sql = "SELECT EVENT_CODE, EVENT_CODE_DESC FROM BX.EVENT_TYPE"
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_evt_type_hash["#{row['EVENT_CODE']}"]= "#{row['EVENT_CODE_DESC']}"
    end
  end

  haml :create_event
end

get '/create_registration' do
  session!
  @db_event_hash = {}
  sql = "SELECT EVENT_ID,EVENT_DESC FROM BX.EVENT WHERE FBF_STATUS ='O'"
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_event_hash["#{row['EVENT_ID']}"]= "#{row['EVENT_DESC']}"
    end
  end
  haml :registraton
end

post '/create_event' do
  session!
  tablename = "BX.EVENT"
  e_description = params[:e_description]
  e_type = params[:e_type]
  e_country = params[:e_country]
  e_city = params[:e_city]
  e_venue = params[:e_venue]
  e_date = params[:e_date]
  e_stime = params[:e_stime]
  e_etime = params[:e_etime]
  e_manager = params[:e_manager]
  em_email = params[:em_email]
  em_tel = params[:em_tel]
  ep_name = params[:ep_name]
  ep_email = params[:ep_email]
  ep_tel = params[:ep_tel]
  e_status = params[:e_status]
  fbf_status = params[:fbf_status]
  e_notes = params[:e_notes]
  formatted_e_date = e_date.gsub(/\-/,"")
  eventID = "BX" + e_type + e_country + e_city + formatted_e_date
  sql = "INSERT INTO " + tablename + " VALUES ('#{eventID}','#{e_description}','#{e_type}','#{e_country}','#{e_city}','#{e_venue}','#{e_date}','#{e_stime}','#{e_etime}','#{e_manager}','#{em_email}','#{em_tel}','#{ep_name}','#{ep_email}','#{ep_tel}','#{e_status}','#{fbf_status}','#{e_notes}')"
  IBM_DB.exec(conn, sql)
  redirect '/'
end

post '/track_registrations' do
  session!
  tablename = "BX.REGISTRATION"
  total = String.new
  a_event_id=params[:event_id]
  a_name = params[:a_name]
  a_company = params[:a_company]
  a_email = params[:a_email]
  a_jobrole = params[:a_jobrole]
  a_register_status = params[:a_register_status]
  a_attend_status = params[:a_attend_status]
  a_notes = params[:a_notes]

  sql = "INSERT INTO " + tablename + " VALUES ('#{a_event_id}','#{a_name}','#{a_company}','#{a_email}','#{a_jobrole}','#{a_register_status}','#{a_attend_status}','#{a_notes}')"
  if stmt=IBM_DB.exec(conn, sql)
    total = total + sql + "<BR><BR>\n"
    out = "Statement execution successful!"
    total=total + out + "<BR>\n"
  else
    out = "Statement execution failed: #{IBM_DB.stmt_errormsg}"
    total = total + out + "<BR>\n"
  end
  total
end

post '/RunQuery' do
  if initial_setup != 1 
   session!
  end 
  total = String.new
  query_sql=params[:query]

  sql = "#{query_sql}"
  if stmt=IBM_DB.exec(conn, sql)
    total = total + sql + "<BR><BR>\n"
    out = "Statement execution successful!"
    total=total + out + "<BR><BR>\n"
    if (query_sql =~ /SELECT/i)
      select_query=1
    else
      select_query =0
    end
    if (select_query ==1)
      while row = IBM_DB.fetch_assoc(stmt)
        row.each do |key,value|
          total += " #{row[key]} "
        end
        total += "<BR>\n"
      end
    end
    # free the resources associated with the result set
    IBM_DB.free_result(stmt)
    total += "</table>"
  else
    total = total + sql + "<BR><BR>\n"
    out = "Statement execution failed: #{IBM_DB.stmt_errormsg}"
    total = total + out + "<BR>\n"
  end
  total
end

get '/delete_event' do
  session!
  @db_event_hash = {}
  sql = "SELECT EVENT_ID,EVENT_DESC FROM BX.EVENT "
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_event_hash["#{row['EVENT_ID']}"]= "#{row['EVENT_DESC']}"
    end
  end
  haml :select_delete_event
end

get '/update_event' do
  session!
  @db_event_hash = {}
  sql = "SELECT EVENT_ID,EVENT_DESC FROM BX.EVENT "
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_event_hash["#{row['EVENT_ID']}"]= "#{row['EVENT_DESC']}"
    end
  end
  haml :select_update_event
end

post '/show_delete_event_details' do
  session!

  @db_evt_type_hash = {}
  sql = "SELECT EVENT_CODE, EVENT_CODE_DESC FROM BX.EVENT_TYPE"
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_evt_type_hash["#{row['EVENT_CODE']}"]= "#{row['EVENT_CODE_DESC']}"
    end
  end

  @db_country_hash = {}
  sql = "SELECT COUNTRY_CODE, COUNTRY_NAME FROM BX.COUNTRY"
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_country_hash["#{row['COUNTRY_NAME']}"]= "#{row['COUNTRY_CODE']}"
    end
  end

  @db_city_hash = {}
  sql = "SELECT CITY_CODE, CITY_NAME FROM BX.CITY"
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_city_hash["#{row['CITY_NAME']}"]= "#{row['CITY_CODE']}"
    end
  end

  this_event_id=params[:event_id]
  e_event_id=""
  e_description= ""
  e_type = ""
  e_country = ""
  e_city = ""
  e_venue = ""
  e_date = ""
  e_stime = ""
  e_etime = ""
  e_manager = ""
  em_email = ""
  em_tel = ""
  ep_name = ""
  ep_email = ""
  ep_tel = ""
  e_status = ""
  fbf_status = ""
  e_notes = ""

  sql = "SELECT E.EVENT_ID, E.EVENT_DESC, E.EVENT_TYPE, E.EVENT_COUNTRY,E.EVENT_CITY,E.EVENT_VENUE,E.EVENT_DATE,E.EVENT_START_TIME,
      E.EVENT_END_TIME,E.EVENT_MANAGER, E.MANAGER_EMAIL,E.MANAGER_PHONE, E.EVENT_PRESENTER, E.PRESENTER_EMAIL, E.PRESENTER_PHONE,
      E.EVENT_STATUS,E.FBF_STATUS,E.EVENT_NOTES,
      C.COUNTRY_CODE,C.COUNTRY_NAME,
      T.CITY_CODE,T.CITY_NAME,
      P.EVENT_CODE,P.EVENT_CODE_DESC,
      ES.EVENT_STATUS_CODE, ES.EVENT_STATUS_DESC,
      FS.FBF_STATUS_CODE, FS.FBF_STATUS_DESC
      FROM BX.EVENT E,
           BX.COUNTRY C,
           BX.CITY T,
           BX.EVENT_TYPE P,
           BX.EVENT_STATUS ES,
           BX.FBF_STATUS FS
      WHERE E.EVENT_ID = '#{this_event_id}'
      AND C.COUNTRY_CODE=E.EVENT_COUNTRY
      AND E.EVENT_CITY=T.CITY_CODE
      AND E.EVENT_TYPE=P.EVENT_CODE
      AND E.EVENT_STATUS=ES.EVENT_STATUS_CODE
      AND E.FBF_STATUS=FS.FBF_STATUS_CODE; "
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      e_event_id=row['EVENT_ID']
      e_description = row['EVENT_DESC']
      e_type = row['EVENT_CODE_DESC']
      e_country = row['COUNTRY_NAME']
      e_city = row['CITY_NAME']
      e_venue = row['EVENT_VENUE']
      e_date = row['EVENT_DATE']
      e_stime = row['EVENT_START_TIME']
      e_etime = row['EVENT_END_TIME']
      e_manager = row['EVENT_MANAGER']
      em_email = row['MANAGER_EMAIL']
      em_tel = row['MANAGER_PHONE']
      ep_name = row['EVENT_PRESENTER']
      ep_email = row['PRESENTER_EMAIL']
      ep_tel = row['PRESENTER_PHONE']
      e_status = row['EVENT_STATUS_DESC']
      fbf_status = row['FBF_STATUS_DESC']
      e_notes = row['EVENT_NOTES']
    end
  end
  haml :delete_event, :locals => {:event_id => e_event_id,:event_desc => e_description,:event_type => e_type,:event_country => e_country,:event_city => e_city,:event_venue => e_venue,:event_date => e_date,:event_start_time => e_stime,:event_end_time => e_etime,:event_manager => e_manager,:event_manager_email => em_email,:event_manager_tel => em_tel,:event_type => e_type,:event_presenter_name => ep_name,:event_presenter_email => ep_email,:event_presenter_tel => ep_tel,:event_status => e_status,:fbf_status => fbf_status,:event_notes => e_notes }
end

post '/delete_event_action' do
  session!
  table_name="BX.EVENT"
  this_event_id=params[:event_id]
  sql = "DELETE  from #{table_name} where EVENT_ID = '#{this_event_id}'"
  IBM_DB.exec(conn, sql)
  redirect '/'
end

post '/show_update_event_details' do
  session!
  this_event_id=params[:event_id]
  e_event_id=""
  e_description= ""
  e_type = ""
  e_country = ""
  e_city = ""
  e_venue = ""
  e_date = ""
  e_stime = ""
  e_etime = ""
  e_manager = ""
  em_email = ""
  em_tel = ""
  ep_name = ""
  ep_email = ""
  ep_tel = ""
  e_status = ""
  fbf_status = ""
  e_notes = ""

  @db_country_hash = {}
  sql = "SELECT COUNTRY_CODE, COUNTRY_NAME FROM BX.COUNTRY"
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_country_hash["#{row['COUNTRY_NAME']}"]= "#{row['COUNTRY_CODE']}"
    end
  end

  @db_fbf_hash = {}
  sql = "SELECT FBF_STATUS_CODE, FBF_STATUS_DESC FROM BX.FBF_STATUS"
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_fbf_hash["#{row['FBF_STATUS_CODE']}"]= "#{row['FBF_STATUS_DESC']}"
    end
  end

  @db_evt_status_hash = {}
  sql = "SELECT EVENT_STATUS_CODE, EVENT_STATUS_DESC FROM BX.EVENT_STATUS"
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_evt_status_hash["#{row['EVENT_STATUS_CODE']}"]= "#{row['EVENT_STATUS_DESC']}"
    end
  end

  @db_city_hash = {}
  @db_cc_hash = {}
  @country_name_selected=""
  sql = "SELECT CITY_CODE, CITY_NAME, COUNTRY_NAME FROM BX.CITY"
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_city_hash["#{row['CITY_CODE']}"]= "#{row['CITY_NAME']}"
      @db_cc_hash["#{row['CITY_NAME']}"] = "#{row['COUNTRY_NAME']}"
    end
  end

  @db_evt_type_hash = {}
  sql = "SELECT EVENT_CODE, EVENT_CODE_DESC FROM BX.EVENT_TYPE"
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_evt_type_hash["#{row['EVENT_CODE']}"]= "#{row['EVENT_CODE_DESC']}"
    end
  end

  sql = "SELECT E.EVENT_ID, E.EVENT_DESC, E.EVENT_TYPE, E.EVENT_COUNTRY,E.EVENT_CITY,E.EVENT_VENUE,E.EVENT_DATE,E.EVENT_START_TIME,
      E.EVENT_END_TIME,E.EVENT_MANAGER, E.MANAGER_EMAIL,E.MANAGER_PHONE, E.EVENT_PRESENTER, E.PRESENTER_EMAIL, E.PRESENTER_PHONE,
      E.EVENT_STATUS,E.FBF_STATUS,E.EVENT_NOTES,
      C.COUNTRY_CODE,C.COUNTRY_NAME,
      T.CITY_CODE,T.CITY_NAME,
      P.EVENT_CODE,P.EVENT_CODE_DESC,
      ES.EVENT_STATUS_CODE, ES.EVENT_STATUS_DESC,
      FS.FBF_STATUS_CODE, FS.FBF_STATUS_DESC
      FROM BX.EVENT E,
           BX.COUNTRY C,
           BX.CITY T,
           BX.EVENT_TYPE P,
           BX.EVENT_STATUS ES,
           BX.FBF_STATUS FS
      WHERE E.EVENT_ID = '#{this_event_id}'
      AND C.COUNTRY_CODE=E.EVENT_COUNTRY
      AND E.EVENT_CITY=T.CITY_CODE
      AND E.EVENT_TYPE=P.EVENT_CODE
      AND E.EVENT_STATUS=ES.EVENT_STATUS_CODE
      AND E.FBF_STATUS=FS.FBF_STATUS_CODE; "
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      e_event_id=row['EVENT_ID']
      e_description = row['EVENT_DESC']
      e_type = row['EVENT_CODE_DESC']
      e_country = row['COUNTRY_NAME']
      e_city = row['CITY_NAME']
      e_venue = row['EVENT_VENUE']
      e_date = row['EVENT_DATE']
      e_stime = row['EVENT_START_TIME']
      e_etime = row['EVENT_END_TIME']
      e_manager = row['EVENT_MANAGER']
      em_email = row['MANAGER_EMAIL']
      em_tel = row['MANAGER_PHONE']
      ep_name = row['EVENT_PRESENTER']
      ep_email = row['PRESENTER_EMAIL']
      ep_tel = row['PRESENTER_PHONE']
      e_status = row['EVENT_STATUS_DESC']
      fbf_status = row['FBF_STATUS_DESC']
      e_notes = row['EVENT_NOTES']
    end
  end
  haml :update_event, :locals => {:event_id => e_event_id,:event_desc => e_description,:event_type => e_type,:event_country => e_country,:event_city => e_city,:event_venue => e_venue,:event_date => e_date,:event_start_time => e_stime,:event_end_time => e_etime,:event_manager => e_manager,:event_manager_email => em_email,:event_manager_tel => em_tel,:event_type => e_type,:event_presenter_name => ep_name,:event_presenter_email => ep_email,:event_presenter_tel => ep_tel,:event_status => e_status,:fbf_status => fbf_status,:event_notes => e_notes }
end

post '/update_event_action' do
  session!
  table_name="BX.EVENT"
  this_event_id=params[:event_id]
  this_event_desc=params[:e_description]
  this_event_type=params[:e_type]
  this_event_country=params[:e_country]
  this_event_city=params[:e_city]
  this_event_venue=params[:e_venue]
  this_event_date=params[:e_date]
  this_event_start_time=params[:e_stime]
  this_event_end_time=params[:e_etime]
  this_event_manager=params[:e_manager]
  this_event_manager_email=params[:em_email]
  this_event_manager_tel=params[:em_tel]
  this_event_presenter=params[:ep_name]
  this_event_presenter_email=params[:ep_email]
  this_event_presenter_tel=params[:ep_tel]
  this_event_status=params[:e_status]
  this_event_fbf_status=params[:fbf_status]
  this_event_notes=params[:e_notes]
  formatted_e_date = this_event_date.gsub(/\-/,"")
  new_event_id = "BX" + this_event_type + this_event_country + this_event_city + formatted_e_date
  
  sql = "update #{table_name} set EVENT_ID='#{new_event_id}',
                                  EVENT_DESC='#{this_event_desc}',
                                  EVENT_TYPE = '#{this_event_type}',
                                  EVENT_COUNTRY = '#{this_event_country}',
                                  EVENT_CITY = '#{this_event_city}',
                                  EVENT_VENUE = '#{this_event_venue}',
                                  EVENT_DATE = '#{this_event_date}',
                                  EVENT_START_TIME = '#{this_event_start_time}',
                                  EVENT_END_TIME = '#{this_event_end_time}',
                                  EVENT_MANAGER = '#{this_event_manager}',
                                  MANAGER_EMAIL = '#{this_event_manager_email}',
                                  MANAGER_PHONE = '#{this_event_manager_tel}',
                                  EVENT_PRESENTER = '#{this_event_presenter}',
                                  PRESENTER_EMAIL = '#{this_event_presenter_email}',
                                  PRESENTER_PHONE = '#{this_event_presenter_tel}',
                                  EVENT_STATUS = '#{this_event_status}',
                                  FBF_STATUS = '#{this_event_fbf_status}',
                                  EVENT_NOTES = '#{this_event_notes}'
           WHERE EVENT_ID = '#{this_event_id}';  "

  IBM_DB.exec(conn, sql)
  redirect '/'
end

get '/create_city' do
  session!
  sql_append_city = ""  
  if session[:usertype] == "USR" || session[:usertype] == "OPR"  
    sql_append_city = "WHERE COUNTRY_NAME = '#{session[:usercountry]}'"         
  end
  @db_country_hash = {}
  sql = "SELECT COUNTRY_CODE, COUNTRY_NAME FROM BX.COUNTRY #{sql_append_city}"
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_country_hash["#{row['COUNTRY_CODE']}"]= "#{row['COUNTRY_NAME']}"
    end
  end

  @db_city_status_hash = {}
  sql = "SELECT CITY_STATUS_CODE, CITY_STATUS_DESC FROM BX.CITY_STATUS "
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_city_status_hash["#{row['CITY_STATUS_CODE']}"]= "#{row['CITY_STATUS_DESC']}"
    end
  end

  haml :create_city
end

post '/create_city_action' do
  session!
  table_name="BX.CITY"
  this_city_code=params[:city_code]
  this_city_name=params[:city_name]
  this_city_state=params[:state_name]
  this_city_country=params[:country_name]
  this_city_status=params[:city_status]
  sql = "INSERT INTO  #{table_name} VALUES ('#{this_city_code}','#{this_city_name}','#{this_city_state}','#{this_city_country}','#{this_city_status}');"
  IBM_DB.exec(conn, sql)
  redirect '/'
end

get '/update_city' do
  session!
  sql_append_city = ""  
  if session[:usertype] == "USR" || session[:usertype] == "OPR"  
    sql_append_city = "WHERE COUNTRY_NAME = '#{session[:usercountry]}'"         
  end
  
  @db_city_hash = {}
  sql = "SELECT CITY_CODE,CITY_NAME FROM BX.CITY #{sql_append_city}"
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_city_hash["#{row['CITY_CODE']}"]= "#{row['CITY_NAME']}"
    end
  end
  haml :select_update_city
end

get '/delete_city' do
  session!
  sql_append_city = ""  
  if session[:usertype] == "USR" || session[:usertype] == "OPR"  
    sql_append_city = "WHERE COUNTRY_NAME = '#{session[:usercountry]}'"         
  end
  
  @db_city_hash = {}
  sql = "SELECT CITY_CODE,CITY_NAME FROM BX.CITY #{sql_append_city}"
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_city_hash["#{row['CITY_CODE']}"]= "#{row['CITY_NAME']}"
    end
  end
  haml :select_delete_city
end

post '/show_city_details_for_update' do
  session!
  total = String.new
  table_name="BX.CITY"
  this_city_code=params[:city_code]
  city_name=""
  state_name= ""
  country_name = ""
  city_status = ""

  @db_country_hash = {}
  sql = "SELECT COUNTRY_CODE, COUNTRY_NAME FROM BX.COUNTRY"
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_country_hash["#{row['COUNTRY_CODE']}"]= "#{row['COUNTRY_NAME']}"
    end
  end

  @db_city_status_hash = {}
  sql = "SELECT CITY_STATUS_CODE, CITY_STATUS_DESC FROM BX.CITY_STATUS "
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_city_status_hash["#{row['CITY_STATUS_CODE']}"]= "#{row['CITY_STATUS_DESC']}"
    end
  end

  sql = "SELECT * from #{table_name} where CITY_CODE = '#{this_city_code}'"
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      c_city_code=row['CITY_CODE']
      c_city_name = row['CITY_NAME']
      c_state_name = row['STATE_NAME']
      c_country_name = row['COUNTRY_NAME']
      c_status = row['STATUS']
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution successful: #{IBM_DB.stmt_errormsg}"
      total = total + out + "<BR>\n"
    end
  else
    total = total + sql + "<BR><BR>\n"
    out = "Statement execution failed: #{IBM_DB.stmt_errormsg}"
    total = total + out + "<BR>\n"
  end
  total
  haml :update_city, :locals => {:city_code => c_city_code,:city_name => c_city_name,:state_name => c_state_name,:country_name => c_country_name,:city_status => c_status }
end

post '/show_city_details_for_delete' do

  session!
  total = String.new
  table_name="BX.CITY"
  this_city_code=params[:city_code]
  city_name=""
  state_name= ""
  country_name = ""
  city_status = ""

  @db_country_hash = {}
  sql = "SELECT COUNTRY_CODE, COUNTRY_NAME FROM BX.COUNTRY"
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_country_hash["#{row['COUNTRY_CODE']}"]= "#{row['COUNTRY_NAME']}"
    end
  end

  @db_city_status_hash = {}
  sql = "SELECT CITY_STATUS_CODE, CITY_STATUS_DESC FROM BX.CITY_STATUS "
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_city_status_hash["#{row['CITY_STATUS_CODE']}"]= "#{row['CITY_STATUS_DESC']}"
    end
  end

  sql = "SELECT * from #{table_name} where CITY_CODE = '#{this_city_code}'"
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      c_city_code=row['CITY_CODE']
      c_city_name = row['CITY_NAME']
      c_state_name = row['STATE_NAME']
      c_country_name = row['COUNTRY_NAME']
      c_status = row['STATUS']
      total = total + sql + "<BR><BR>\n"
      out = "Statement execution successful: #{IBM_DB.stmt_errormsg}"
      total = total + out + "<BR>\n"
    end
  else
    total = total + sql + "<BR><BR>\n"
    out = "Statement execution failed: #{IBM_DB.stmt_errormsg}"
    total = total + out + "<BR>\n"
  end
  total
  haml :delete_city, :locals => {:city_code => c_city_code,:city_name => c_city_name,:state_name => c_state_name,:country_name => c_country_name,:city_status => c_status }
end

post '/update_city_action' do
  session!
  this_city_code=params[:city_code]
  this_city_status=params[:city_status]
  sql = "update BX.CITY set STATUS = '#{this_city_status}' WHERE CITY_CODE = '#{this_city_code}';"
  IBM_DB.exec(conn, sql)
  redirect '/'
end

post '/delete_city_action' do
  session!
  table_name="BX.CITY"
  this_city_code=params[:city_code]
  this_city_status=params[:city_status]
  sql = "DELETE FROM #{table_name} WHERE CITY_CODE = '#{this_city_code}';"
  IBM_DB.exec(conn, sql)
  redirect '/'
end

get '/create_user' do
  session!
  total = String.new
  sql_append_country = ""
  
  if session[:usertype] == "USR" || session[:usertype] == "OPR"  
    sql_append_country = "WHERE COUNTRY_NAME = '#{session[:usercountry]}'"        
  end
  
  @db_country_hash = {}
  sql = "SELECT COUNTRY_CODE, COUNTRY_NAME FROM BX.COUNTRY #{sql_append_country}"
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_country_hash["#{row['COUNTRY_NAME']}"]= "#{row['COUNTRY_CODE']}"
    end
  end

  haml :create_user
end

post '/create-account' do
  username = params[:username]
  useremail = params[:email]
  userpassword = params[:passwordInitial]
  usercountry = params[:usercountry]
  userrole = params[:role]
  userstatus = params[:status]
  IBM_DB.exec(conn, "INSERT INTO BX.USER VALUES ('#{useremail}', ENCRYPT('#{userpassword}','#{useremail}'),'#{username}','#{usercountry}','#{userrole}','#{userstatus}')")
  redirect '/'
end

get '/edit_user' do
  session!
  sql_append = ""
  if (session[:usertype] == "ADM")
    @db_user_hash = {}
    sql = "SELECT USER_ID,USER_NAME FROM BX.USER "
    if stmt = IBM_DB.exec(conn, sql)
      while row = IBM_DB.fetch_assoc(stmt)
        @db_user_hash["#{row['USER_ID']}"]= "#{row['USER_NAME']}"
      end
    end
    haml :select_update_user
  elsif (session[:usertype] == "OPR") 
    sql_append = "AND COUNTRY = '#{session[:usercountry]}'"

    @db_user_hash = {}
    sql = "SELECT USER_ID,USER_NAME FROM BX.USER WHERE (ROLE = 'OPR' OR ROLE='USR') #{sql_append} "
    if stmt = IBM_DB.exec(conn, sql)
      while row = IBM_DB.fetch_assoc(stmt)
        @db_user_hash["#{row['USER_ID']}"]= "#{row['USER_NAME']}"
      end
    end
    haml :select_update_user
  else
    redirect '/'
  end
end

get '/delete_user' do
  session!
  sql_append = ""
  if (session[:usertype] == "ADM")
    @db_user_hash = {}
    sql = "SELECT USER_ID,USER_NAME FROM BX.USER "
    if stmt = IBM_DB.exec(conn, sql)
      while row = IBM_DB.fetch_assoc(stmt)
        @db_user_hash["#{row['USER_ID']}"]= "#{row['USER_NAME']}"
      end
    end
    haml :select_delete_user
  elsif (session[:usertype] == "OPR") 
    sql_append = "AND COUNTRY = '#{session[:usercountry]}'"

    @db_user_hash = {}
    sql = "SELECT USER_ID,USER_NAME FROM BX.USER WHERE (ROLE = 'OPR' OR ROLE='USR') #{sql_append} "
    if stmt = IBM_DB.exec(conn, sql)
      while row = IBM_DB.fetch_assoc(stmt)
        @db_user_hash["#{row['USER_ID']}"]= "#{row['USER_NAME']}"
      end
    end
    haml :select_delete_user
  else
    redirect '/'
  end
end

post '/select_user_to_update' do
  session!
  thisuser = params[:user_id]
  u_id = ""
  u_password = ""
  u_username = ""
  u_country = ""
  u_role = ""
  u_status = ""
  sql_append_country = ""
  
  if session[:usertype] == "USR" || session[:usertype] == "OPR"  
    sql_append_country = "WHERE COUNTRY_NAME = '#{session[:usercountry]}'"        
  end
  
  @db_country_hash = {}
   
  sql = "SELECT COUNTRY_CODE, COUNTRY_NAME FROM BX.COUNTRY #{sql_append_country}"
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_country_hash["#{row['COUNTRY_NAME']}"]= "#{row['COUNTRY_CODE']}"
    end
  end

  sql = "SELECT USER_ID, DECRYPT_CHAR(PASSWORD, '#{thisuser}') AS PASSWORD, USER_NAME, COUNTRY, ROLE, STATUS from BX.USER where USER_ID = '#{thisuser}'"
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      u_id=row['USER_ID']
      u_password=row['PASSWORD']
      u_username=row['USER_NAME']
      u_country=row['COUNTRY']
      u_role=row['ROLE']
      u_status=row['STATUS']
    end
  end
  haml :update_user, :locals => {:email => u_id,:password => u_password,:username => u_username,:country_name => u_country,:role => u_role,:status => u_status }
end

post '/select_user_to_delete' do
  session!
  table_name="BX.USER"
  this_user_id = params[:user_id]
  sql = "DELETE FROM #{table_name} WHERE USER_ID ='#{this_user_id}';"
  IBM_DB.exec(conn, sql)
  redirect '/'
end

post '/update_account' do
  session!
  table_name="BX.USER"
  nusername = params[:username]
  nuseremail = params[:email]
  nuserpassword = params[:passwordInitial]
  nusercountry = params[:usercountry]
  nuserrole = params[:role]
  nuserstatus = params[:status]

  sql = "update #{table_name} set PASSWORD = ENCRYPT('#{nuserpassword}','#{nuseremail}'), USER_NAME = '#{nusername}', COUNTRY = '#{nusercountry}', ROLE = '#{nuserrole}', STATUS = '#{nuserstatus}' WHERE USER_ID = '#{nuseremail}'; "
  IBM_DB.exec(conn, sql)
  redirect '/'
end
#=-=-=-=-=-=-=-EDIT HERE!!!=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
get '/generate_report' do
  session!
  @db_event_hash = {}
  sql = "SELECT EVENT_ID,EVENT_DESC FROM BX.EVENT "
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      @db_event_hash["#{row['EVENT_ID']}"]= "#{row['EVENT_DESC']}"
    end
  end
  haml :select_event_feed_back
end    
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#=-=-=-=-=-=-=-GENERATE FEEDBACK REPORT-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=
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
 

get '/change_password' do
  session!
  thisuser = thisUserID
  table_name = "BX.USER"
  sql = "SELECT USER_ID from #{table_name} where USER_ID = '#{thisuser}'"
  if stmt = IBM_DB.exec(conn, sql)
    while row = IBM_DB.fetch_assoc(stmt)
      u_id=row['USER_ID']
    end
  end
  haml :change_password, :locals => {:email => u_id }
end

post '/change_password_action' do
  session!
  table_name="BX.USER"
  user_id=thisUserID
  new_password = params[:passwordInitial]
  sql = "UPDATE #{table_name} SET PASSWORD = ENCRYPT('#{new_password}','#{user_id}') WHERE USER_ID = '#{user_id}'; "
  IBM_DB.exec(conn, sql)
  redirect '/'
  
end

