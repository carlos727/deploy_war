# Cookbook Name:: deploy_war
# Recipe:: reverse
# Script to reverse the process if it fails
# Copyright (c) 2016 The Authors, All Rights Reserved.

#------------ Variables -------------#
reachable = false
prefix = ''

#----------- Main Process -----------#
ruby_block 'Verify deployment (reverse)' do
  block do
    reachable = Tools.isReachable?('http://localhost:8080/Eva/apilocalidad/version')

    if reachable
      f = Tools.fetch 'http://localhost:8080/Eva/apilocalidad/version'
      prefix = "B" if $node_name.include? "B"
      message = "Successful deployment, Eva v#{f["version"]} is ready in #{f["codLocalidad"]} #{f["descripLocalidad"]} !"
      Chef::Log.info(message)
      Tools.simple_email node["mail"]["to"], :message => message, :subject => "Chef Deployment on Node #{prefix}#{f["codLocalidad"]}"
    end
  end
end

ruby_block 'Undeploy Eva (reverse)' do
  block do
    Eva.undeploy($username, $password)
  end
  not_if { reachable }
end

# Stop Tomcat7
windows_service 'Stop Tomcat7 (reverse)' do
  service_name 'Tomcat7'
  action :stop
  not_if { reachable }
end

ruby_block 'wait while tomcat is stopped (reverse)' do
  block do
    Tomcat.waitStop
  end
  not_if { reachable }
end

# Execute command to copy current war into the folder previously created.
powershell_script 'Restore current war' do
  code "copy \'C:\\chef\\WarBackup\\Eva.war'  \'#{$war_folder}\'"
  not_if { reachable }
end

# Start Tomcat.
windows_service 'Start Tomcat7 (reverse)' do
  service_name 'Tomcat7'
  action :start
  not_if { reachable }
end

ruby_block 'wait for tomcat to start (reverse)' do
  block do
    Tomcat.waitStart
  end
  not_if { reachable }
end

ruby_block 'Wait while Eva is deployed (reverse)' do
  block do
    Eva.deploy($username, $password)
  end
  not_if { reachable }
end

ruby_block 'Verify reverse' do
  block do
    if Tools.isReachable?('http://localhost:8080/Eva')
      message = "Something unexpected happened, Eva reversed to its previous state."
      Chef::Log.info(message)
      Tools.send_email node["mail"]["to"], :message => message
    else
      Chef::Log.error("Request failed.")
    end
    Eva.expireSessions($username, $password)
  end
  not_if { reachable }
end
