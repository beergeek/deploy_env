class profile::bamboo_server (
  # Bamboo
  Profile::Pathurl            $source_location          = 'https://product-downloads.atlassian.com/software/bamboo/downloads',
  Boolean                     $manage_bamboo_grp        = true,
  Boolean                     $manage_bamboo_user       = true,
  Stdlib::Absolutepath        $bamboo_data_dir          = '/var/atlassian/application-data/bamboo',
  Stdlib::Absolutepath        $bamboo_install_dir       = '/opt/atlassian/bamboo',
  String                      $bamboo_grp               = 'bamboo',
  String                      $bamboo_user              = 'bamboo',
  String                      $bamboo_version           = '6.6.1',
  Array[Stdlib::Absolutepath] $bamboo_base_dirs         = ['/opt/atlassian','/var/atlassian','/var/atlassian/application-data'],

  # Firewall
  Boolean                     $enable_firewall          = true,
  Hash                        $firewall_rule_defaults   = {ensure => present, proto => 'tcp', action => 'accept'},
  Optional[Hash]              $firewall_rules           = {},

  # Database
  Boolean                     $manage_db_settings       = true,
  Profile::Db_type            $db_type                  = 'postgresql',
  Optional[Stdlib::Fqdn]      $db_host                  = 'localhost',
  Optional[String]            $db_name                  = 'bamboodb',
  Optional[String]            $db_password              = undef,
  Optional[String]            $db_port                  = undef,
  Optional[String]            $db_user                  = 'bamboo',

  # Noop
  Boolean                     $noop_scope               = false,
) {

  if $noop_scope {
    noop(true)
  }

  include profile::docker

  file { $bamboo_base_dirs:
    ensure  => directory,
    owner   => $bamboo_user,
    group   => $bamboo_grp,
    mode    => '0755',
  }

  if $manage_db_settings {
    if $db_type == 'postgresql' {
      require profile::database_services::postgresql

      postgresql::server::db { $bamboodb:
        user      => $db_user,
        password  => $db_password,
        locale    => 'en_AU',
        encoding  => 'UTF8',
        grant     => ['ALL'],
      }
    } elsif $db_type == 'mysql' {
      require profile::database_services::mysql

      mysql::db { $db_name:
        ensure    => present,
        user      => $db_user,
        password  => $db_password,
        charset   => 'utf8',
        collate   => 'utf8_bin',
        grant     => ['ALL'],
      }
    }
  }

  if $enable_firewall {
    if $firewall_rules {
      $firewall_rules.each |String $rule_name, Hash $rule_data| {
        firewall { $rule_name:
          *   => $rule_data;
          default:
            * => $firewall_rule_defaults,
        }
      }
    }
  }

  java::oracle { 'jdk8' :
    ensure  => 'present',
    version => '8',
    java_se => 'jdk',
  }

  class { '::bamboo':
    bamboo_data_dir     => $bamboo_data_dir,
    bamboo_grp          => $bamboo_bamboo_grp,
    bamboo_install_dir  => $bamboo_install_dir,
    bamboo_user         => $bamboo_bamboo_user,
    db_host             => $db_host,
    db_name             => $db_name,
    db_password         => $db_password,
    db_port             => $db_port,
    db_type             => $db_type,
    db_user             => $db_user,
    manage_db_settings  => $manage_db_settings,
    manage_grp          => $manage_bamboo_grp,
    manage_user         => $manage_bamboo_grp,
    source_location     => $source_location,
    version             => $bamboo_version,
    require => Java::Oracle['jdk8'],
  }

  file { "${bamboo_data_dir}/bamboo.jks":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  java_ks { 'bamboo_ks':
    ensure       => latest,
    certificate  => '/etc/puppetlabs/puppet/ssl/certs/ca.pem',
    target       => "${bamboo_data_dir}/bamboo.jks",
    password     => 'changeit',
    trustcacerts => true,
    require      => [Java::Oracle['jdk8'],File["${bamboo_data_dir}/bamboo.jks"]],
  }

}
