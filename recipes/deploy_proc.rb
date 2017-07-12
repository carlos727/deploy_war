# Cookbook Name:: deploy_war
# Recipe:: deploy_proc
# Script with deploy process
# Copyright (c) 2016 The Authors, All Rights Reserved.

#------------ Variables -------------#
first_time = true
undeploy = true
prefix = ''

#----------- Main Process -----------#
log "Eva.war downloaded from #{$war_url}" do
  action :nothing
end

# Verify if Eva is deployed already
ruby_block 'Verify if Eva is deployed' do
  block do
    if Eva.status?($username, $password)[0]
      first_time = false
      Chef::Log.info("Eva will be updated.")
    else
      Chef::Log.info("Eva will be deployed for the first time.")
    end
  end
end

# Create backupWar folder to store war files replaced.
directory "C:\\chef\\WarBackup" do
  not_if { File.directory?("C:\\chef\\WarBackup") || first_time }
end

# Delete the war previously was replaced
file "C:\\chef\\WarBackup\\Eva.war" do
  action :delete
  only_if { File.exist?("C:\\chef\\WarBackup\\Eva.war") }
end

# Execute command to copy current war into the folder previously created.
powershell_script 'Store current war' do
  code "copy \'#{$war_folder}\\Eva.war\' \'C:\\chef\\WarBackup\'"
  only_if { File.directory?("C:\\chef\\WarBackup") && File.exist?("#{$war_folder}\\Eva.war") }
end

ruby_block 'Undeploy Eva (Manager)' do
  block do
    undeploy = Eva.undeploy($username, $password)
  end
end

# Stop Tomcat7
windows_service 'Stop Tomcat7 (deploy)' do
  service_name 'Tomcat7'
  action :stop
end

ruby_block 'wait while tomcat is stopped' do
  block do
    Tomcat.waitStop
  end
end

# Delete current war.
file "#{$war_folder}\\Eva.war" do
  action :delete
  only_if { File.exist?("#{$war_folder}\\Eva.war") && !undeploy }
end

# Delete Eva's folder.
directory "#{$war_folder}\\Eva" do
  recursive true
  action :delete
  only_if { File.directory?("#{$war_folder}\\Eva") && !undeploy }
end

# Execute command to copy new war into the webapps folder
powershell_script 'Copy new war' do
  code "copy \'C:\\chef\\New_War\\Eva.war\' \'#{$war_folder}\'"
  only_if { File.exist?("C:\\chef\\New_War\\Eva.war") }
end

# Download the war from remote source if it's necessary.
remote_file 'Download Eva.war' do
  path "#{$war_folder}\\Eva.war"
  source $war_url
  notifies :write, "log[Eva.war downloaded from #{$war_url}]", :immediately
  not_if { File.exist?("C:\\chef\\New_War\\Eva.war") }
end

# Start Tomcat.
windows_service 'Start Tomcat7 (deploy)' do
  service_name 'Tomcat7'
  action :start
end

# Ruby code to pause chef-client in runtime while tomcat start completely
ruby_block 'wait for tomcat to start (deploy)' do
  block do
    Tomcat.waitStart
  end
end

# Ruby code to pause chef-client in runtime while Eva deploy completely
ruby_block 'Wait while Eva is deployed' do
  block do
    Eva.deploy($username, $password)
  end
end

# Ruby code to verify the deployment of Eva
ruby_block 'Verify deployment' do
  block do
    if Tools.isReachable?('http://localhost:8080/Eva/apilocalidad/version')
      f = Tools.fetch 'http://localhost:8080/Eva/apilocalidad/version'
      prefix = "B" if $node_name.start_with? "B"
      prefix = "P" if $node_name.start_with? "P"
      message = "Successful deployment, Eva v#{f["version"]} is ready in #{f["codLocalidad"]} #{f["descripLocalidad"]} !"
      Chef::Log.info(message)
      Tools.simple_email node["mail"]["to"], :message => message, :subject => "Chef Deployment on Node #{prefix}#{f["codLocalidad"]}"
    else
      Chef::Log.error("Request failed.")
    end
  end
end
