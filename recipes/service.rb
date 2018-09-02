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

auto_restart = node[cookbook_name]['auto_restart']

node[cookbook_name]['components'].each_pair do |comp, config|
  next unless config['install?']
  configfile = "#{node[cookbook_name]['prefix_home']}/#{comp}/#{comp}.yml"

  if node['platform'] == "ubuntu" && node['platform_version'].to_f <= 14.10
    template "/etc/init/#{comp}.conf" do
      source 'upstart/component.conf.erb'
      owner 'root'
      group 'root'
      mode '644'
      variables(
        comp: comp,
        user: node[cookbook_name]['user'],
        group: node[cookbook_name]['group'],
        path: config['path'],
        cli: config['cli']
      )
      if auto_restart
        notifies :try_restart, "service[#{comp}]", :delayed
      end
    end

    service comp do
      supports :restart => true
      action [:enable, :start]
      subscribes :reload_or_try_restart, "file[#{configfile}]" if auto_restart
      subscribes :try_restart, "service[#{comp}]" if auto_restart
    end
  else
    systemd_unit "#{comp}.service" do
      content config['unit']
      action %i[create enable start]
      subscribes :reload_or_try_restart, "file[#{configfile}]" if auto_restart
      subscribes :try_restart, "systemd_unit[#{comp}.service]" if auto_restart
    end
  end
end
