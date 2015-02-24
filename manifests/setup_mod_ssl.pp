# == Class: shibboleth::setup_mod_ssl
#
# To manage Setting up an SSL secured Apache for Shibboleth.
#
# === Authors
#
# Jeffery Bagirimvano <jeffery.rukundo@gmail.com>
#
# === Copyright
#
# Copyright 2014 Jeffery B.
#

class shibboleth::setup_mod_ssl {
  require shibboleth::setup_apache

  if $shibboleth::configure_mod_ssl {
    if $shibboleth::install_mod_ssl_pkg {
      shibboleth::repos { 'default': }

      if $::osfamily == 'RedHat' {
        package {
          $shibboleth::params::mod_ssl_package_name:
            ensure => installed;

          $shibboleth::params::shib_package_name:
            ensure  => installed,
            require => Exec['Add yum repository'],
        }
      }

      if $::osfamily == 'Debian' {
        package { $shibboleth::params::mod_ssl_package_name: ensure => installed, }
      }
    } else {
      fail("The shibboleth Puppet module does not support mod_ssl on this ${::osfamily} family of operating systems")
    }

    if $shibboleth::manage_ssl_certificate {
      # In case you have another module to manage $install_openssl_pkg,
      # you can turn this off and won't cause conflicts.
      if $shibboleth::install_openssl_pkg {
        package { $shibboleth::params::openssl_package_name: ensure => installed, }
      }

      # This generates a self signed x509 certificate used to secure connections.
      # If the key is ever lost or overwritten
      # the certificate will have to be re-registered.
      # Alternativly, the certificate could be deployed from the puppetmaster
      $self_signed_cert = "openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${shibboleth::params::cert_name}.key -out ${shibboleth::params::cert_name}.crt -subj '/C=${shibboleth::params::country}/ST=${shibboleth::params::state}/L=${shibboleth::params::locality}/O=${shibboleth::params::organization}/OU=${shibboleth::params::unit}/CN=${::fqdn}'"
      $cert_signing_request = "openssl req -out ${shibboleth::params::cert_name}.csr -key ${shibboleth::params::cert_name}.key -new -subj '/C=${shibboleth::params::country}/ST=${shibboleth::params::state}/L=${shibboleth::params::locality}/O=${shibboleth::params::organization}/OU=${shibboleth::params::unit}/CN=${::fqdn}'"

      if $shibboleth::create_ssl_cert {
        exec { "Generate a self-signed certificate for ${::hostname}":
          cwd      => $shibboleth::params::certs_dir,
          command  => "${self_signed_cert} && ${cert_signing_request}",
          unless   => "openssl x509 -in ${shibboleth::params::cert_name}.crt -text -noout|grep ${::fqdn}",
          provider => 'shell',
          path     => ['/sbin', '/bin', '/usr/sbin', '/usr/bin'];
        }
      } else {
        # PROVIDE YOUR BACKED-UP/CREATED CERTIFICATE & KEY
        staging::file {
          "Getting ${::hostname}.key":
            source  => $shibboleth::params::key_cert_source,
            target  => "${shibboleth::params::certs_dir}/${::hostname}.key",
            notify  => Service['shibd'],
            require => Package[$shibboleth::params::shib_package_name];

          "Getting ${::hostname}.crt":
            source  => $shibboleth::params::csr_cert_source,
            target  => "${shibboleth::params::certs_dir}/${::hostname}.crt",
            notify  => Service['shibd'],
            require => Package[$shibboleth::params::shib_package_name];
        }

        exec { "Setting Permissions on ${::hostname}.key":
          command  => "chmod 0444 ${shibboleth::params::certs_dir}/${::hostname}.key",
          unless   => "/bin/sh -c '[ $(/usr/bin/stat -c %a ${shibboleth::params::certs_dir}/${::hostname}.key) == 444 ]'",
          require  => Staging::File["Getting ${::hostname}.key"],
          provider => 'shell',
          path     => ['/sbin', '/bin', '/usr/sbin', '/usr/bin'];
        }

        exec { "Setting Permissions on ${::hostname}.crt":
          command  => "chmod 0444 ${shibboleth::params::certs_dir}/${::hostname}.crt",
          unless   => "/bin/sh -c '[ $(/usr/bin/stat -c %a ${shibboleth::params::certs_dir}/${::hostname}.crt) == 444 ]'",
          require  => Staging::File["Getting ${::hostname}.crt"],
          provider => 'shell',
          path     => ['/sbin', '/bin', '/usr/sbin', '/usr/bin'];
        }
        #        file {
        #          "${shibboleth::params::certs_dir}/${::hostname}.key":
        #            mode    => '0400',
        #            owner   => 'root',
        #            group   => 'root',
        #            require => Staging::File["Getting ${::hostname}.key"];
        #
        #          "${shibboleth::params::certs_dir}/${::hostname}.crt":
        #            mode    => '0400',
        #            owner   => 'root',
        #            group   => 'root',
        #            require => Staging::File["Getting ${::hostname}.crt"];
        #        }
      }

      if $shibboleth::sslCertificateChainFile {
        staging::file { 'Getting incommon-chain.crt':
          source  => $shibboleth::params::incommon_cert_source,
          target  => "${shibboleth::params::certs_dir}/incommon-chain.crt",
          notify  => Service['shibd'],
          require => Package[$shibboleth::params::shib_package_name];
        }

        exec { 'Setting Permissions on incommon-chain.crt':
          command  => "chmod 0444 ${shibboleth::params::certs_dir}/incommon-chain.crt",
          unless   => "/bin/sh -c '[ $(/usr/bin/stat -c %a ${shibboleth::params::certs_dir}/incommon-chain.crt) == 444 ]'",
          require  => Staging::File['Getting incommon-chain.crt'],
          provider => 'shell',
          path     => ['/sbin', '/bin', '/usr/sbin', '/usr/bin'];
        }

        #        file { "${certs_dir}/incommon-chain.crt":
        #          mode    => '0400',
        #          owner   => 'root',
        #          group   => 'root',
        #          source  => $incommon_cert_source,
        #          notify  => Service['shibd'],
        #          require => Package[$shibboleth::params::shib_package_name];
        #        }

        if $::osfamily == 'RedHat' {
          apache_directive { 'SSLCertificateChainFile':
            ensure  => present,
            args    => "${shibboleth::params::certs_dir}/incommon-chain.crt",
            context => 'VirtualHost[arg="_default_:443"]',
            notify  => Service[$shibboleth::params::apache_service_name, 'shibd'],
            require => Package[$shibboleth::params::mod_ssl_package_name],
            target  => $shibboleth::params::ssl_conf_file;
          }
        }

        if $::osfamily == 'Debian' {
          apache_directive { 'SSLCertificateChainFile':
            ensure  => present,
            args    => "${shibboleth::params::certs_dir}/incommon-chain.crt",
            context => 'IfModule/VirtualHost[arg="_default_:443"]',
            notify  => Service[$shibboleth::params::apache_service_name, 'shibd'],
            require => Package[$shibboleth::params::mod_ssl_package_name],
            target  => $shibboleth::params::ssl_conf_file;
          }
        }
      } else {
        if $::osfamily == 'RedHat' {
          apache_directive { 'SSLCertificateChainFile':
            ensure  => absent,
            args    => "${shibboleth::params::certs_dir}/incommon-chain.crt",
            context => 'VirtualHost[arg="_default_:443"]',
            notify  => Service[$shibboleth::params::apache_service_name, 'shibd'],
            require => Package[$shibboleth::params::mod_ssl_package_name],
            target  => $shibboleth::params::ssl_conf_file;
          }
        }

        if $::osfamily == 'Debian' {
          apache_directive { 'SSLCertificateChainFile':
            ensure  => absent,
            args    => "${shibboleth::params::certs_dir}/incommon-chain.crt",
            context => 'IfModule/VirtualHost[arg="_default_:443"]',
            notify  => Service[$shibboleth::params::apache_service_name, 'shibd'],
            require => Package[$shibboleth::params::mod_ssl_package_name],
            target  => $shibboleth::params::ssl_conf_file;
          }
        }

      }
    }

    $workaround = '\$1'
    $apache_add_mod_rewrite = "bash -c 'cat <<EOT >> ${shibboleth::params::apache_conf_file}

###################################################
# Mod Rewrite to move people off insecure port 80 #
###################################################

<IfModule mod_rewrite.c>
       RewriteEngine On
       RewriteCond %{HTTPS} !=on
       # This checks to make sure the connection is not already HTTPS
       RewriteRule ^/?(.*) https://%{SERVER_NAME}/${workaround} [R,L]
       # This rule will redirect users from their original location, to the same location but using HTTPS.
       # i.e.  http://www.example.com/foo/ to https://www.example.com/foo/
</IfModule>

EOT'"

    exec { 'Insert IfModule mod_rewrite.c Section':
      command  => $apache_add_mod_rewrite,
      unless   => "grep 'RewriteCond %{HTTPS} !=on' ${shibboleth::params::apache_conf_file}",
      require  => Package[$shibboleth::params::apache_package_name],
      notify   => Service[$shibboleth::params::apache_service_name, 'shibd'],
      provider => 'shell',
      path     => ['/sbin', '/bin', '/usr/sbin', '/usr/bin'];
    }

    if $shibboleth::session_location == undef {
      fail("Please set your 'session_location'. This should be the location to secure. e.g if you want to protect 'mysite' at https://example.com/mysite, then do: class { 'kualicoeus': session_location => 'mysite' }"
      )
    }

    # Configure ssl.conf file...
    if $::osfamily == 'Debian' {
      # Enable the module
      file { "${shibboleth::params::apache_sites_enabled}/default-ssl.conf":
        ensure => 'link',
        target => "${shibboleth::params::apache_sites_available}/default-ssl.conf",
        notify => Service['shibd'],
      }

      apache_directive {
        'ServerName':
          ensure  => present,
          args    => "${::fqdn}:443",
          context => 'IfModule/VirtualHost[arg="_default_:443"]',
          notify  => Service[$shibboleth::params::apache_service_name, 'shibd'],
          require => Package[$shibboleth::params::mod_ssl_package_name],
          target  => $shibboleth::params::ssl_conf_file;

        'ServerAdmin':
          ensure  => present,
          args    => $shibboleth::admin,
          context => 'IfModule/VirtualHost[arg="_default_:443"]',
          notify  => Service[$shibboleth::params::apache_service_name, 'shibd'],
          require => Package[$shibboleth::params::mod_ssl_package_name],
          target  => $shibboleth::params::ssl_conf_file;

        'SSLCertificateFile':
          ensure  => present,
          args    => "${shibboleth::params::certs_dir}/${::hostname}.crt",
          context => 'IfModule/VirtualHost[arg="_default_:443"]',
          notify  => Service[$shibboleth::params::apache_service_name, 'shibd'],
          require => Package[$shibboleth::params::mod_ssl_package_name],
          target  => $shibboleth::params::ssl_conf_file;

        'SSLCertificateKeyFile':
          ensure  => present,
          args    => "${shibboleth::params::certs_dir}/${::hostname}.key",
          context => 'IfModule/VirtualHost[arg="_default_:443"]',
          notify  => Service[$shibboleth::params::apache_service_name, 'shibd'],
          require => Package[$shibboleth::params::mod_ssl_package_name],
          target  => $shibboleth::params::ssl_conf_file;

        'SSLSessionCacheTimeout':
          ensure  => present,
          args    => $shibboleth::sslSessionCacheTimeout,
          context => 'IfModule[arg="mod_ssl.c"]',
          notify  => Service[$shibboleth::params::apache_service_name, 'shibd'],
          require => Package[$shibboleth::params::mod_ssl_package_name],
          target  => "${shibboleth::params::apache_mods_location}/ssl.conf";
      } ->
      # Mod Rewrite to move people off the root
      augeas { 'Add IfModule mod_rewrite':
        lens    => 'Httpd.lns',
        incl    => $shibboleth::params::ssl_conf_file,
        context => "/files${shibboleth::params::ssl_conf_file}/IfModule/VirtualHost",
        changes => [
          'set IfModule/arg mod_rewrite.c',
          'set IfModule/#comment[1] -----------------------------------------',
          "set IfModule/#comment[2] 'Mod Rewrite to move people off the root'",
          'set IfModule/#comment[3] -----------------------------------------',
          'set IfModule/directive[1]  RewriteEngine',
          'set IfModule/directive[1]/arg  On',
          'set IfModule/directive[2] RewriteRule',
          'set IfModule/directive[2]/arg[1] ^/$',
          "set IfModule/directive[2]/arg[2] /${shibboleth::session_location}",
          'set IfModule/directive[2]/arg[3] [R]',
          ],
        notify  => Service[$shibboleth::params::apache_service_name, 'shibd'],
        require => Package[$shibboleth::params::mod_ssl_package_name];
      }
    }

    if $::osfamily == 'RedHat' {
      apache_directive {
        'ServerName':
          ensure  => present,
          args    => "${::fqdn}:443",
          context => 'VirtualHost[arg="_default_:443"]',
          notify  => Service[$shibboleth::params::apache_service_name, 'shibd'],
          require => Package[$shibboleth::params::mod_ssl_package_name],
          target  => $shibboleth::params::ssl_conf_file;

        'ServerAdmin':
          ensure  => present,
          args    => $shibboleth::admin,
          context => 'VirtualHost[arg="_default_:443"]',
          notify  => Service[$shibboleth::params::apache_service_name, 'shibd'],
          require => Package[$shibboleth::params::mod_ssl_package_name],
          target  => $shibboleth::params::ssl_conf_file;

        'SSLSessionCacheTimeout':
          ensure  => present,
          args    => $shibboleth::sslSessionCacheTimeout,
          notify  => Service[$shibboleth::params::apache_service_name, 'shibd'],
          require => Package[$shibboleth::params::mod_ssl_package_name],
          target  => $shibboleth::params::ssl_conf_file;

        'SSLCertificateFile':
          ensure  => present,
          args    => "${shibboleth::params::certs_dir}/${::hostname}.crt",
          context => 'VirtualHost[arg="_default_:443"]',
          notify  => Service[$shibboleth::params::apache_service_name, 'shibd'],
          require => Package[$shibboleth::params::mod_ssl_package_name],
          target  => $shibboleth::params::ssl_conf_file;

        'SSLCertificateKeyFile':
          ensure  => present,
          args    => "${shibboleth::params::certs_dir}/${::hostname}.key",
          context => 'VirtualHost[arg="_default_:443"]',
          notify  => Service[$shibboleth::params::apache_service_name, 'shibd'],
          require => Package[$shibboleth::params::mod_ssl_package_name],
          target  => $shibboleth::params::ssl_conf_file;
      } ->
      # Mod Rewrite to move people off the root
      augeas { 'Add IfModule mod_rewrite':
        lens    => 'Httpd.lns',
        incl    => $shibboleth::params::ssl_conf_file,
        context => "/files${shibboleth::params::ssl_conf_file}/VirtualHost",
        changes => [
          'set IfModule/arg mod_rewrite.c',
          'set IfModule/#comment[1] -----------------------------------------',
          "set IfModule/#comment[2] 'Mod Rewrite to move people off the root'",
          'set IfModule/#comment[3] -----------------------------------------',
          'set IfModule/directive[1]  RewriteEngine',
          'set IfModule/directive[1]/arg  On',
          'set IfModule/directive[2] RewriteRule',
          'set IfModule/directive[2]/arg[1] ^/$',
          "set IfModule/directive[2]/arg[2] /${shibboleth::session_location}",
          'set IfModule/directive[2]/arg[3] [R]',
          ],
        notify  => Service[$shibboleth::params::apache_service_name, 'shibd'],
        require => Package[$shibboleth::params::mod_ssl_package_name];
      }
    }
  }
}
