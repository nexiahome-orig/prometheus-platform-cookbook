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

cookbook_name = 'prometheus-platform'

# Where to get the tarball for Prometheus server
mirror = 'https://github.com/prometheus/' \
  '%<comp>s/releases/download/v%<version>s'
file = '%<comp>s-%<version>s.linux-amd64.tar.gz'

# Prometheus package and version from https://prometheus.io/download
# Set install? to true to install a component
# For each component, the url field will be added later in the file
#   'url' => url of file, default: "#{mirror}/#{file}"
default[cookbook_name]['components'] = {
  'prometheus' => {
    'install?' => false,
    'version' => '2.3.2',
    'sha' => '351931fe9bb252849b7d37183099047fbe6d7b79dcba013fb6ae19cc1bbd8552'
  },
  'alertmanager' => {
    'install?' => false,
    'version' => '0.15.2',
    'sha' => '79ee23ab2f0444f592051995728ba9e0a7547cc3b9162301e3152dbeaf568d2e'
  },
  'blackbox_exporter' => {
    'install?' => false,
    'version' => '0.12.0',
    'sha' => 'c5d8ba7d91101524fa7c3f5e17256d467d44d5e1d243e251fd795e0ab4a83605'
  },
  'consul_exporter' => {
    'install?' => false,
    'version' => '0.4.0',
    'sha' => 'ff77c03de67cf381f67480b5be6699901785a34145c518c3484ae3e5b8440d08'
  },
  'graphite_exporter' => {
    'install?' => false,
    'version' => '0.3.0',
    'sha' => '2ef1f11cbf928c003bf8c015b4b4ba3e7bb5ff26d13a6fb51c39236e66b9b588'
  },
  'haproxy_exporter' => {
    'install?' => false,
    'version' => '0.9.0',
    'sha' => 'b0d1caaaf245d3d16432de9504575b3af1fec14b2206a468372a80843be001a0'
  },
  'memcached_exporter' => {
    'install?' => false,
    'version' => '0.4.1',
    'sha' => 'f7f2511efab64de701e9303516ed1595e4e3ad4edea527338de64c8484aca7a6'
  },
  'mysqld_exporter' => {
    'install?' => false,
    'version' => '0.11.0',
    'sha' => 'b53ad48ff14aa891eb6a959730ffc626db98160d140d9a66377394714c563acf'
  },
  'node_exporter' => {
    'install?' => false,
    'version' => '0.16.0',
    'sha' => 'e92a601a5ef4f77cce967266b488a978711dabc527a720bea26505cba426c029'
  },
  'pushgateway' => {
    'install?' => false,
    'version' => '0.5.2',
    'sha' => 'd4aeb15b9667bae79170d4f12b4afa20dc29850aeac2ce071479d93057fb5c3b'
  },
  'statsd_exporter' => {
    'install?' => false,
    'version' => '0.7.0',
    'sha' => 'cd8e7fadda7e6a390208916bdbab13b21624bd0a80e928ddccdc1cf33ec463e9'
  }
}

# User and group of prometheus process
default[cookbook_name]['user'] = 'prometheus'
default[cookbook_name]['group'] = 'prometheus'

# Ark stuff (Installation), shared for all components
default[cookbook_name]['prefix_root'] = '/opt' # base installation dir
default[cookbook_name]['prefix_home'] = '/opt' # where is link to install dir
default[cookbook_name]['prefix_bin'] = '/opt/bin' # where to link binaries

# Default unit file, can be modified/extended for each component
default[cookbook_name]['default']['unit'] = {
  'Unit' => {
    'Description' => 'Prometheus platform: %<comp>s',
    'After' => 'network.target'
  },
  'Service' => {
    'Type' => 'simple',
    'User' => node[cookbook_name]['user'],
    'Group' => node[cookbook_name]['group'],
    'WorkingDirectory' => '%<path>s',
    'SyslogIdentifier' => '%<comp>s',
    'Restart' => 'on-failure',
    'ExecStart' => '%<cli>s'
  },
  'Install' => {
    'WantedBy' => 'multi-user.target'
  }
}

# Rules dir, will be created and populated by 'rules' attributes
default[cookbook_name]['components']['prometheus']['rules_dir'] = 'rules'

# Prometheus main config
default[cookbook_name]['components']['prometheus']['config'] = {
  'rule_files' => [
    "#{node[cookbook_name]['components']['prometheus']['rules_dir']}/*"
  ],
  'global' => {
    'scrape_interval' => '15s',
    'evaluation_interval' => '15s'
    # 'external_labels' => {
    #   'monitor' => 'codelab-monitor'
    # }
  },
  'alerting' => {
    'alertmanagers' => [{
      'static_configs' => [{
        'targets' => ["#{node['fqdn']}:9093"]
      }]
    }]
  },
  # 'scrape_configs' => { # will be converted to array (see below)
  #   'index_1' =>
  #   {
  #     'job_name' => 'prometheus',
  #     'scrape_interval' => '5s',
  #     'static_configs' => {
  #       'index_1' => {
  #         'targets' => ['localhost:9090', 'localhost:9100']
  #       }
  #     }
  #   }
  # }
  # this scrape_configs entry is equivalent and will be rewritten to:
  # 'scrape_configs' => [
  #   {
  #     'job_name' => 'prometheus',
  #     'scrape_interval' => '5s',
  #     'static_configs' => {
  #       'index_1' => {
  #         'targets' => ['localhost:9090', 'localhost:9100']
  #       }
  #     }
  #   }
  # ]

  # Actually, all hash containing a key 'index_xxxx' will be rewritten like
  # that. This is to permit the overriding of default values in role attribute.
}

# Scrape_configs can be configured directly in config or in the following
# attributes which will be interpreted by scraper recipe,
# using cluster-search cookbook

# First default config that will be merged in all scrapers config
default[cookbook_name]['components']['prometheus']['scrapers_default'] = {
  # Example:
  # 'relabel_configs' => [
  #    'source_labels' => ['__address__'],
  #    'regex' => '([^:]+):(.*)',
  #    'replacement' => '$1',
  #    'target_label' => 'instance'
  #  ]
}

# Then scrapers list
default[cookbook_name]['components']['prometheus']['scrapers'] = {
  # Example:
  # 'node_exporter' => {
  #   'scrape_interval' => '60s',
  #   'static_configs' => { # use cluster-search (search on a role)
  #     'role' => 'prometheus-platform',
  #     'port' => '9100'
  #   }
  # }
}

# Prometheus launch configuration, stored in systemd unit
# Use '' if no value is needed
default[cookbook_name]['components']['prometheus']['cli_opts'] = {
  'config.file' => '%<path>s/%<cfile>s',
  'storage.tsdb.path' => '/var/opt/prometheus',
  'storage.tsdb.retention' => '15d'
}

# Extra configuration for systemd unit, will be merged with default
default[cookbook_name]['components']['prometheus']['unit'] = {
  'Service' => {
    'LimitNOFILE' => 65_536
  }
}

# Rules configuration for Prometheus, will be in rules_dir
default[cookbook_name]['components']['prometheus']['rules'] = {
  # file => array of rules where a rule is a string, or an array of string
  # example:
  #   'alerting' => [],
  #   'recording' => []
}

# Alertmanager configuration, empty by default which is non-working
default[cookbook_name]['components']['alertmanager']['config'] = {}

# Alertmanager launch configuration, stored in systemd unit
# Use '' if no value is needed
default[cookbook_name]['components']['alertmanager']['cli_opts'] = {
  'config.file' => '%<path>s/%<cfile>s',
  'storage.path' => '/var/opt/alertmanager'
}

# Simple proc to do a deep merge on hash
deep_merge = proc do |_, old, new|
  old.respond_to?(:merge) ? old.merge(new, &deep_merge) : new
end

# Merge global default with each component default
node[cookbook_name]['components'].each_pair do |comp, config|
  default[cookbook_name]['components'][comp]['url'] = "#{mirror}/#{file}"

  default_unit = node[cookbook_name]['default']['unit'].to_h
  current_unit = config['unit'] || {}
  default[cookbook_name]['components'][comp]['unit'] =
    default_unit.merge(current_unit, &deep_merge)
end

def interpol(conf, keys)
  if conf.is_a?(String)
    conf % keys
  elsif conf.is_a?(Hash)
    conf.map { |k, v| [k, interpol(v, keys)] }.to_h
  else conf
  end
end

def opts_to_str(hash)
  (hash || {}).map { |k, v| "#{' ' * 2}--#{k}#{"=#{v}" unless v.empty?}" }
end

# Fill in previous configurations, replace %<token>s with actual value
node[cookbook_name]['components'].each_pair do |comp, config|
  path = "#{node[cookbook_name]['prefix_home']}/#{comp}"
  cfile = "#{comp}.yml"
  bin = "#{path}/#{comp}"

  keys = {
    path: path,
    cfile: cfile,
    bin: bin,
    comp: comp,
    version: config['version']
  }

  # cli need substitution too
  cli = [bin, opts_to_str(config['cli_opts'])].flatten.join(" \\\n") % keys
  keys[:cli] = cli
  default[cookbook_name]['components'][comp] = interpol(config.to_h, keys)
  default[cookbook_name]['components'][comp]['cli'] = cli
end

# Should we restart service after config update?
default[cookbook_name]['auto_restart'] = true

# Configure retries for the package resources, default = global default (0)
# (mostly used for test purpose
default[cookbook_name]['package_retries'] = nil
