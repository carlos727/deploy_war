include Chef::Mixin::PowershellOut
# Define general functions, methods, tools and utilities
module Tools
  require 'net/smtp'
  require 'json'
  require 'net/http'
  require 'mechanize'

  # Method to make web scraping and return body content
  def self.webScraping(url, username, password)
    agent = Mechanize.new
    agent.user_agent_alias = 'Windows Chrome'

    unless username.nil?
      agent.add_auth(url, username, password)
    end
    res = agent.get(url)
    return (res.body).to_s
  end

  # Function to know if one url is reachable
  def self.isReachable?(url)
    sw = true
    agent = Mechanize.new
    agent.user_agent_alias = 'Windows Chrome'
    agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    tries = 3
    cont = 0

    begin
    	agent.read_timeout = 5 #set the agent time out
    	page = agent.get(url)
  	rescue
      cont += 1
      unless (tries -= 1).zero?
        Chef::Log.warn("Verifying if url #{url} is reachable (#{cont}/3) failed, try again in 1 minutes...")
        agent.shutdown
        agent = Mechanize.new { |agent| agent.user_agent_alias = 'Windows Chrome'}
        agent.request_headers
        sleep(60)
        retry
      else
        Chef::Log.error("The url #{url} isn't available.")
        sw = false
      end
    else
      sw = true
    ensure
      agent.history.pop()   #delete this request in the history
    end

    return sw
  end

  # Method to fetch data in JSON format from an URL
  def self.fetch(url)
    resp = Net::HTTP.get_response(URI.parse(url))
    data = resp.body
    return JSON.parse(data)
  end

  # Method to start SQLSERVER
  def self.waitSQLSERVER
    connectable = false
    3.times do
      sql = powershell_out!("Invoke-Sqlcmd -Query \'Select name From sys.databases\'")

      if sql.stdout[/error/].nil?
        connectable = true
        Chef::Log.info("SQLSERVER Started.")
        break
      else
        Chef::Log.info("Waiting 20 seconds for SQLSERVER to continue...")
        sleep(20)
      end
    end

    unless connectable
      Chef::Log.error("Could not connect to the SQLSERVER database.")
    end
  end

  def self.unindent string
    first = string[/\A\s*/]
    string.gsub /^#{first}/, ''
  end

  def self.send_email(to ,opts={})
    opts[:server]      ||= 'smtp.office365.com'
    opts[:port]        ||= 587
    opts[:from]        ||= 'barcoder@redsis.com'
    opts[:password]    ||= 'Orion2015'
    opts[:from_alias]  ||= 'Chef Reporter'
    opts[:subject]     ||= "Chef Deployment on Node #{Chef.run_context.node.name}"
    opts[:message]     ||= "..."

    filename = "C:\\chef\\log-#{Chef.run_context.node.name}"
    # Read a file and encode it into base64 format
    encodedcontent = [File.read(filename)].pack("m")   # base64

    marker = "AUNIQUEMARKER"

    # Define the main headers.
    header = <<-HEADER
      From: #{opts[:from_alias]} <#{opts[:from]}>
      To: <#{to}>
      Subject: #{opts[:subject]}
      MIME-Version: 1.0
      Content-Type: multipart/mixed; boundary=#{marker}
      --#{marker}
    HEADER

    # Define the message action
    body = <<-BODY
      Content-Type: text/plain
      Content-Transfer-Encoding:8bit

      #{opts[:message]}
      --#{marker}
    BODY

    # Define the attachment section
    attached = <<-ATTACHED
      Content-Type: multipart/mixed; name=\"#{filename}\"
      Content-Transfer-Encoding:base64
      Content-Disposition: attachment; filename="#{filename}"

      #{encodedcontent}
      --#{marker}--
    ATTACHED

    mailtext = unindent header + body + attached

    smtp = Net::SMTP.new(opts[:server], opts[:port])
    smtp.enable_starttls_auto
    smtp.start(opts[:server], opts[:from], opts[:password], :login)
    smtp.send_message(mailtext, opts[:from], to)
    smtp.finish
  end

  def self.simple_email(to, opts={})
    opts[:server]      ||= 'smtp.office365.com'
    opts[:port]        ||= 587
    opts[:from]        ||= 'barcoder@redsis.com'
    opts[:password]    ||= 'Orion2015'
    opts[:from_alias]  ||= 'Chef Reporter'
    opts[:subject]     ||= "Chef Start on Node #{Chef.run_context.node.name}"
    opts[:message]     ||= "..."

    message = <<-MESSAGE
      From: #{opts[:from_alias]} <#{opts[:from]}>
      To: <#{to}>
      Subject: #{opts[:subject]}

      #{opts[:message]}
    MESSAGE

    mailtext = unindent message

    smtp = Net::SMTP.new(opts[:server], opts[:port])
    smtp.enable_starttls_auto
    smtp.start(opts[:server], opts[:from], opts[:password], :login)
    smtp.send_message(mailtext, opts[:from], to)
    smtp.finish
  end
end

# Define functions, methods, tools and utilities to work with Tomcat
module Tomcat
  require 'mechanize'

  # Function to get the war folder
  def self.getWarFolder
    if File.directory?("C:\\Program Files (x86)\\Apache Software Foundation\\Tomcat 7.0\\webapps")
      return "C:\\Program Files (x86)\\Apache Software Foundation\\Tomcat 7.0\\webapps"
    else
      return "C:\\Program Files\\Apache Software Foundation\\Tomcat 7.0\\webapps"
    end
  end

  # Function to know if tomcat is Running
  def self.isRunning?
    tomcat = powershell_out!("(Get-Service Tomcat7).Status -eq \'Running\'")

    if tomcat.stdout[/True/]
      return true
    else
      return false
    end
  end

  # Function to know if tomcat is Stop
  def self.isStop?
    tomcat = powershell_out!("(Get-Service Tomcat7).Status -eq \'Stopped\'")

    if tomcat.stdout[/True/]
      return true
    else
      return false
    end
  end

  # Method to pause execution while tomcat start
  def self.waitStart
    if isRunning?
      agent = Mechanize.new
      agent.user_agent_alias = 'Windows Chrome'

    	begin
      	agent.read_timeout = 5 #set the agent time out
      	page = agent.get('http://localhost:8080')
      	agent.history.pop()   #delete this request in the history
        Chef::Log.info("Tomcat7 Started")
    	rescue
    		Chef::Log.info("Waiting 2.5 minutes for Tomcat7 to continue...")
    		agent.shutdown
    		agent = Mechanize.new { |agent| agent.user_agent_alias = 'Windows Chrome'}
    		agent.request_headers
    		sleep(150)
    		retry
    	end
    end
  end

  # Method to pause execution while tomcat stop
  def self.waitStop
    while !isStop? do
      Chef::Log.info("Waiting 2 minutes for Tomcat7 to continue...")
      sleep(120)
    end
    Chef::Log.info("Tomcat7 stopped !")
  end

  # Method to get the list of applications deployed and its number of sessions
  def self.sessionList(username, password)
    session_mesage = Tools.webScraping('http://localhost:8080/manager/text/list', username, password)
    sessions = Array.new

    session_mesage.each_line do |line|
      session = line.split(':')
      sessions.push(session)
    end
    return sessions
  end

  # Function to validate if there are active sessions in tomcat manager
  def self.activeSessions?(username, password)
    if isRunning?
      sessions = sessionList(username, password)
      i = 0
      sw = false
      while (i < sessions.length && !sw)
        session = sessions[i]
        if (session[0].start_with?("/") && !session[0].eql?("/manager") && session[2].to_i > 0)
          sw = true
        end
        i += 1
      end
      return sw
    else
      return false
    end
  end
end

# Define functions, methods, tools and utilities to work with Eva
module Eva
  require 'mechanize'

  # Function to know if Eva is Running
  def self.status?(username, password)
    if Tomcat.isRunning?
      sessions = Tomcat.sessionList(username, password)
      i = 0
      exist = false
      status = ""
      while (i < sessions.length && !exist)
        session = sessions[i]
        if (session[0].eql?("/Eva"))
          exist = true
          status = session[1]
        end
        i += 1
      end
      return [exist, status]
    else
      return [false, ""]
    end
  end

  # Method to start Eva
  def self.start(username, password)
    # Verify if Eva exist and it is sttoped
    if status?(username, password)[0] && status?(username, password)[1].eql?("stopped")
      agent = Mechanize.new
      agent.user_agent_alias = 'Windows Chrome'
      agent.add_auth('http://localhost:8080/manager/text/start?path=/Eva', username, password)
      page = agent.get('http://localhost:8080/manager/text/start?path=/Eva')

      while status?(username, password)[1].eql?("stopped") do
        Chef::Log.info("Waiting 2 minutes while starting Eva to continue...")
        sleep(120)
      end

      Chef::Log.info("Eva Started !")
    end
  end

  # Method to stop Eva
  def self.stop(username, password)
    if status?(username, password)[0] && status?(username, password)[1].eql?("running")
      agent = Mechanize.new
      agent.user_agent_alias = 'Windows Chrome'
      agent.add_auth('http://localhost:8080/manager/text/stop?path=/Eva', username, password)
      page = agent.get('http://localhost:8080/manager/text/stop?path=/Eva')

      while status?(username, password)[1].eql?("running") do
        Chef::Log.info("Waiting 2 minutes while stopping Eva to continue...")
        sleep(120)
      end

      Chef::Log.info("Eva Stopped !")
    end
  end

  # Method to undeploy Eva
  def self.undeploy(username, password)
    if status?(username, password)[0]
      sw = true
      agent = Mechanize.new
      agent.user_agent_alias = 'Windows Chrome'
      tries = 3
      cont = 0

      begin
        agent.add_auth('http://localhost:8080/manager/text/undeploy?path=/Eva', username, password)
        page = agent.get('http://localhost:8080/manager/text/undeploy?path=/Eva')
      rescue
        cont += 1
        unless (tries -= 1).zero?
          Chef::Log.warn("Undeploy Eva (#{cont}/3) failed, try again in 1 minutes...")
          agent.shutdown
          agent = Mechanize.new { |agent| agent.user_agent_alias = 'Windows Chrome'}
          agent.request_headers
          sleep(60)
          retry
        else
          Chef::Log.error("Could not execute undeploy Eva.")
          sw = false
        end
      else
        sw = true
      ensure
        agent.history.pop()   #delete this request in the history
      end

      if sw
        i = 0
        while status?(username, password)[0] && i < 5 do
          Chef::Log.info("Waiting 2 minutes while undeploying Eva to continue...")
          i += 1
          sleep(120)
        end

        if status?(username, password)[0]
          agent.shutdown
          sleep(60)
      		agent = Mechanize.new { |agent| agent.user_agent_alias = 'Windows Chrome'}

          begin
            agent.add_auth('http://localhost:8080/manager/text/undeploy?path=/Eva', username, password)
            page = agent.get('http://localhost:8080/manager/text/undeploy?path=/Eva')
          rescue
            Tools.simple_email 'cbeleno@redsis.com', :message => 'Needing a manual adjustment !', :subject => "Chef Undeploy on Node #{Chef.run_context.node.name}"
          end

          i = 0
          while status?(username, password)[0] && i < 5 do
            Chef::Log.info("Waiting 2 minutes more while undeploying Eva to continue...")
            i += 1
            sleep(120)
          end
        end

        unless status?(username, password)[0]
          Chef::Log.info("Eva Undeployed !")
          return true
        else
          Chef::Log.info("Could not undeploy Eva.")
          return false
        end

      else
        return false
      end

    end
  end

  # Method to deploy Eva
  def self.deploy(username, password)
    while !status?(username, password)[0] &&  !status?(username, password)[1].eql?("running") do
      Chef::Log.info("Waiting 2 minutes for Eva to continue...")
      sleep(120)
    end

    Chef::Log.info("Eva Deployed !")
    Chef::Log.info("Waiting 2 minutes more to continue...")
    sleep(120)
  end

  # Function to validate if the version of new war is the same than the current
  def self.isCurrentVersion?(war_url, username, password)
  	sw = false
  	if status?(username, password)[0]
      if Tools.isReachable?('http://localhost:8080/Eva/apilocalidad/version')
    		version = Tools.webScraping('http://localhost:8080/Eva/apilocalidad/version', nil, nil)
    		unless version[/\d+(\.)\d+(\.)\d+/].nil?
    			current_version = version[/\d+(.)\d+(.)\d+/]
    			new_version = war_url[/\d+(.)\d+(.)\d+/]
    			sw = current_version.eql?(new_version)
    		end
      else
        Chef::Log.warn("Could not determine the version of Eva.")
      end
  	end
  	return sw
  end

  def self.expireSessions(username, password)
    agent = Mechanize.new
    agent.user_agent_alias = 'Windows Chrome'
    agent.add_auth('http://localhost:8080/manager/text/expire?path=/Eva&idle=0', username, password)
    page = agent.get('http://localhost:8080/manager/text/expire?path=/Eva&idle=0')
  end
end

Chef::Recipe.send(:include, Tools)
Chef::Recipe.send(:include, Tomcat)
Chef::Recipe.send(:include, Eva)
