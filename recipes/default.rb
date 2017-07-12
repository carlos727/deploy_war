# Cookbook Name:: deploy_war
# Recipe:: default
# Script to decide if deploy or update a war file
# Copyright (c) 2016 The Authors, All Rights Reserved.

#------------ Variables -------------#
$node_name = Chef.run_context.node.name.to_s
$war_folder = Tomcat.getWarFolder
$username = node["tomcat-manager"]["username"]
$password = node["tomcat-manager"]["password"]
$war_url =
  if $node_name.start_with?('B') || $node_name.start_with?('QA') #|| $node_name.start_with?('RD')
    node["war"]["url_bbi"]
  elsif $node_name.start_with? 'P'
    node["war"]["url_panama"]
  else
    node["war"]["url"]
  end
shops = %w(
  100 101 102 103 104 105 106 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 124 125 126 127 128 129 131 134
  135 136 137 139 140 142 143 144 146 147 148 149 151 152 153 156 157 160 161 162 164 165 166 167 168 169 170 171 150 154
)

#------------ Main process -------------#
file 'C:\chef\New_War\Eva.war' do
  action :delete
  only_if { shops.include?($node_name) }
end

# System preconfigurations
include_recipe 'deploy_war::prepare'

# Deploy
include_recipe 'deploy_war::deploy'
