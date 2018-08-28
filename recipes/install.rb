#
# Copyright (c) 2016-2017 Sam4Mobile, 2017-2018 Make.org
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# tar may not be installed by default
package_retries = node[cookbook_name]['package_retries']
package 'tar' do
  retries package_retries unless package_retries.nil?
end

# Create prefix directories
[
  node[cookbook_name]['prefix_root'],
  node[cookbook_name]['prefix_home'],
  node[cookbook_name]['prefix_bin']
].uniq.each do |dir_path|
  directory "prometheus-platform:#{dir_path}" do
    path dir_path
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end
end

node[cookbook_name]['components'].each_pair do |comp, config|
  next unless config['install?']
  # Download and install component
  ark comp do
    action :install
    url config['url']
    prefix_root node[cookbook_name]['prefix_root']
    prefix_home node[cookbook_name]['prefix_home']
    prefix_bin node[cookbook_name]['prefix_bin']
    has_binaries []
    checksum config['checksum']
    version config['version']
  end

  # Extract all config with word 'path' in their key so we can create dirs
  cli_opts = config['cli_opts'] || {}
  paths = cli_opts.keys.keep_if { |k| k.match(/^(.*\.)?path(\..*)?$/) }
  paths.each do |path|
    directory "#{cookbook_name}:#{path}:#{cli_opts[path]}" do
      path cli_opts[path]
      owner node[cookbook_name]['user']
      group node[cookbook_name]['group']
      recursive true
    end
  end
end
