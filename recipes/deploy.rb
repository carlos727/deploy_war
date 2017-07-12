# Cookbook Name:: deploy_war
# Recipe:: deploy
# Script to deploy a war file
# Copyright (c) 2016 The Authors, All Rights Reserved.

#------------ Variables -------------#
activeSessions = false
current_version = false
reachable = false
deploy = false
first_deploy = false
reverse = false

#----------- Main Process -----------#
# Ensure that war file is available to be downloaded
ruby_block 'Verify if war is available' do
  block do
    activeSessions = Tomcat.activeSessions?($username, $password)
    current_version = Eva.isCurrentVersion?($war_url, $username, $password)

    unless activeSessions || current_version
      if File.exist?("C:\\chef\\New_War\\Eva.war")
        Chef::Log.info("The war is available in folder C:\\chef\\New_War\\Eva.war to be deployed.")
      else
        if Tools.isReachable?($war_url)
          Chef::Log.info("The war is available to be downloaded.")
        else
          reachable = true
        end
      end
    end
  end
end

# Ruby code to do the deploy based on some decisions
ruby_block 'Deploy' do
  block do
    # Verify if there are active sessions or if the incoming war has the same version than the current
    unless activeSessions || current_version || reachable
      # if the war previously was deployed, it must be updated else deployed for first time.
      deploy = true
      unless Eva.status?($username, $password)[0]
        first_deploy = true
      end
      # Run deploy process
      run_context.include_recipe 'deploy_war::deploy_proc'
    else
      message = "Nothing to do at #{Time.now.iso8601}, something doesn't allow to continue with chef-client run:"
      message << "\n\- There are at least one open tomcat session." if activeSessions
      message << "\n\- The incoming war has the same version than the current (v#{$war_url[/\d+(.)\d+(.)\d+/]})." if current_version
      message << "\n\- The war is not available, something was wrong." if reachable
      Chef::Log.info(message)
      Tools.simple_email node["mail"]["to"], :message => message
    end
  end
end

# Reverse the Process (optional)
ruby_block 'Reverse the process' do
  block do
    unless Tools.isReachable?('http://localhost:8080/Eva/apilocalidad/version')
      unless first_deploy
        Chef::Log.warn("Something unexpected happened, reversing to the previous state.")
        reverse = true
        # Run reverse process
        run_context.include_recipe 'deploy_war::reverse'
      else
        message = "Something unexpected happened, Eva can not be deployed for first time."
        Chef::Log.fatal(message)
        Tools.send_email node["mail"]["to"], :message => message
      end
    end
  end
  only_if { deploy }
end

# Verify after reverse
ruby_block 'After reverse' do
  block do
    unless Tools.isReachable?('http://localhost:8080/Eva')
      message = "Something unexpected happened, Eva tried to reverse to its previous state but it failed."
      Chef::Log.fatal(message)
      Tools.send_email node["mail"]["to"], :message => message
    end
  end
  only_if { reverse }
end
