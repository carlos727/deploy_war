# Cookbook Name:: deploy_war
# Recipe:: prepare
# Preconfigurations
# Copyright (c) 2016 The Authors, All Rights Reserved.

#------------ logs ------------------#
log 'Service SQLServer started.' do
  action :nothing
end

#----------- Main Process -----------#
# Ruby code to send a simple email
ruby_block 'Report beginning of the update' do
  block do
    message = "Update process started at #{Time.now.iso8601}."
    Chef::Log.info(message)
    Tools.simple_email node["mail"]["to"], :message => message
  end
end

# Ensure that sqlserver is Running
powershell_script 'Start SQLSERVER' do
  code "start-service mssql*"
  notifies :write, 'log[Service SQLServer started.]', :immediately
  ignore_failure true
end
=begin
# Ruby code to pause chef-client in runtime while sql service start completely
ruby_block 'wait for sql service to start' do
  block do
    Tools.waitSQLSERVER
  end
=end

# Ensure that tomcat is Running
windows_service 'Tomcat7' do
  action :start
end

# Ruby code to pause chef-client in runtime while tomcat start completely
ruby_block 'wait for tomcat to start' do
  block do
    Tomcat.waitStart
  end
end
