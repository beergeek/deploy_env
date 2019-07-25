#
class profile::ldap(
  Stdlib::Absolutepath $cacert_file_path,
) {

  file { '/etc/openldap/ldap.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('profile/ldap.conf.epp', {
      tls_cacert => $cacert_file_path,
    }),
  }

}
