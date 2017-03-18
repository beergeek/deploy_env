class profile::dns (
  Boolean $purge      => false,
  Boolean $noop_scope => false,
) {

  validate_bool($purge)
  validate_bool($noop_scope)

  if $::brownfields and $noop_scope {
    noop()
  }

  case $::kernel {
    'Linux': {
      $name_servers = hiera('profile::dns::name_servers',undef)
      if has_key($::networking['interfaces'],'enp0s8') {
        $ip = $::networking['interfaces']['enp0s8']['ip']
      } elsif has_key($::networking['interfaces'],'eth1') {
        $ip = $::networking['interfaces']['eth1']['ip']
      } elsif has_key($::networking['interfaces'],'enp0s3') {
        $ip = $::networking['interfaces']['enp0s3']['ip']
      } elsif has_key($::networking['interfaces'],'eth0') {
        $ip = $::networking['interfaces']['eth0']['ip']
      } else {
        fail("Buggered if I know your IP Address")
      }

      validate_array($name_servers)

      if $name_servers {
        class { '::resolv_conf':
          domainname  => $::domain,
          nameservers => $name_servers,
        }
      }
    }
    'windows': {
      $ip = $::ipaddress
    }
    default: {
      fail("You need an operating system")
    }
  }

  @@host { $::fqdn:
    ensure        => present,
    host_aliases  => [$::hostname],
    ip            => $ip,
  }

  host { 'localhost':
    ensure       => present,
    host_aliases => ['localhost.localdomai','localhost6','localhost6.localdomain6'],
    ip           => '127.0.0.1',
  }

  Host <<| |>>

  if $purge {
    resources { 'host':
      purge => true,
    }
  }
}
