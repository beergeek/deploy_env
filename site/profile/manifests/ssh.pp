class profile::ssh (
  Array $allowed_groups,
  String $banner_content,
  Boolean $enable_firewall,
  Hash $options_hash,
  Boolean $noop_scope = false,
) {

  if $::brownfields and $noop_scope {
    noop()
  }

  validate_bool($enable_firewall)

  if $enable_firewall {
    # include firewall rule
    firewall { '100 allow ssh access':
      dport  => '22',
      proto  => 'tcp',
      action => 'accept',
    }
  }

  @@nagios_service { "${::fqdn}_ssh":
    ensure              => present,
    use                 => 'generic-service',
    host_name           => $::fqdn,
    service_description => "SSH",
    check_command       => 'check_ssh',
    target              => "/etc/nagios/conf.d/${::fqdn}_service.cfg",
    notify              => Service['nagios'],
    require             => File["/etc/nagios/conf.d/${::fqdn}_service.cfg"],
  }

  file { ['/etc/issue','/etc/issue.net']:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $banner_content,
  }

  $ssh_group_hash = {'AllowGroups' => join($allowed_groups, ' ')}

  class { '::ssh::server':
    storeconfigs_enabled => false,
    options              => merge($options_hash, $ssh_group_hash),
  }

}
