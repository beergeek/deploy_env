class profiles::mom {

  $manage_r10k    = hiera('profiles::mom::manage_r10k', true)
  $r10k_sources   = hiera_hash('profiles::mom::r10k_sources', undef)
  $manage_hiera   = hiera('profiles::mom::manage_hiera', true)
  $hiera_backends = hiera_hash('profiles::mom::hiera_backends', undef)
  $hiera_hierarchy = hiera_array('profiles::mom::hiera_hierarchy', undef)

  Firewall {
    before  => Class['profiles::fw::post'],
    require => Class['profiles::fw::pre'],
  }

  firewall { '100 allow puppet access':
    port   => [8140],
    proto  => tcp,
    action => accept,
  }

  firewall { '100 allow mco access':
    port   => [61613],
    proto  => tcp,
    action => accept,
  }

  firewall { '100 allow amq access':
    port   => [61616],
    proto  => tcp,
    action => accept,
  }

  firewall { '100 allow console access':
    port   => [443],
    proto  => tcp,
    action => accept,
  }

  firewall { '100 allow nc access':
    port   => [4433],
    proto  => tcp,
    action => accept,
  }

  firewall { '100 allow puppetdb access':
    port   => [8081],
    proto  => tcp,
    action => accept,
  }

  if $manage_r10k and ! $r10k_sources {
    fail('The hash `r10k_sources` must exist when managing r10k')
  }

  if $manage_hiera and (! $hiera_backends or ! $hiera_hierarchy) {
    fail('The hash `hiera_backends` and array `hiera_hierarchy` must exist when managing hiera')
  }

  if $manage_r10k {
    class { '::r10k':
      sources => $r10k_sources,
      notify  => Exec['r10k_sync'],
    }

    exec { 'r10k_sync':
      command     => '/opt/puppet/bin/r10k deploy environment -p',
      refreshonly => true,
    }
  }

  if $manage_hiera {
    file { '/etc/puppetlabs/puppet/hiera.yaml':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('profiles/hiera.yaml.erb'),
      notify  => Service['pe-puppetserver'],
    }
  }

}