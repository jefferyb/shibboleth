# == Class: shibboleth::setup_shibboleth
#
# To manage Shibboleth's Packages.
#
# === Authors
#
# Jeffery Bagirimvano <jeffery.rukundo@gmail.com>
#
# === Copyright
#
# Copyright 2014 Jeffery B.
#

class shibboleth::setup_shibboleth {
  require shibboleth::setup_apache
  require shibboleth::setup_mod_ssl

  if $::osfamily == 'Debian' {
    $file_to_config = $shibboleth::params::apache_conf_file
  }

  if $::osfamily == 'RedHat' {
    $file_to_config = "${shibboleth::params::apache_mods_location}/shib.conf"
  }

  # Setup AJP13 support in your servlet container
  if $shibboleth::setup_AJP13_support == 'tomcat' {
    if defined(Class['kualicoeus']) {
      $tomcat_base = $::kualicoeus::_catalina_base

      file_line { 'Setting up AJP13 support for tomcat':
        path    => "${tomcat_base}/conf/server.xml",
        line    => '<Connector port="8009" tomcatAuthentication="false" address="127.0.0.1" enableLookups="false" protocol="AJP/1.3" redirectPort="8443" />',
        match   => '<Connector port="8009".*.protocol="AJP/1.3" redirectPort="8443" />',
        notify  => Tomcat::Service['default'],
        require => Tomcat::Instance['kuali_instance'];
      }
    } elsif defined(Class['tomcat']) {
      $tomcat_base = $::tomcat::catalina_base

      file_line { 'Setting up AJP13 support for tomcat':
        path    => "${tomcat_base}/conf/server.xml",
        line    => '<Connector port="8009" tomcatAuthentication="false" address="127.0.0.1" enableLookups="false" protocol="AJP/1.3" redirectPort="8443" />',
        match   => '<Connector port="8009".*.protocol="AJP/1.3" redirectPort="8443" />',
        notify  => Tomcat::Service['default'],
        require => Tomcat::Instance['default'];
      }
    } else {
      $tomcat_base = $::shibboleth::tomcat_base

      file_line { 'Setting up AJP13 support for tomcat':
        path  => "${tomcat_base}/conf/server.xml",
        line  => '<Connector port="8009" tomcatAuthentication="false" address="127.0.0.1" enableLookups="false" protocol="AJP/1.3" redirectPort="8443" />',
        match => '<Connector port="8009".*.protocol="AJP/1.3" redirectPort="8443" />';
      }
    }
  }

  $shib_add_auth_section = "bash -c 'cat <<EOT >> ${file_to_config}

##########################################################
# Secure with Shibboleth authentication when implemented #
##########################################################

<Location /${shibboleth::session_location}>
       AuthType shibboleth
       ShibRequestSetting requireSession 1
       require valid-user
</Location>
  
EOT'"

  exec { 'Configure Secure Session Location':
    command  => $shib_add_auth_section,
    unless   => "grep '<Location /${shibboleth::session_location}>' ${file_to_config}",
    provider => 'shell',
    require  => Package[$shibboleth::params::shib_package_name],
    notify   => Service[$shibboleth::params::apache_service_name, 'shibd'],
    path     => ['/sbin', '/bin', '/usr/sbin', '/usr/bin'];
  }

  # This generates a self signed x509 certificate used to secure connections
  # with a Shibboleth Federation registry. If the key is ever lost or overwritten
  # the certificate will have to be re-registered.
  # Alternativly, the certificate could be deployed from the puppetmaster
  if $shibboleth::manage_shib_certificate {
    if $::osfamily == 'Debian' {
      $gen_shib_cert_key_cmd = "shib-keygen -f -u _shibd -h ${::fqdn} -y 100 -e https://${::fqdn}/shibboleth -o /etc/shibboleth/"
    }

    if $::osfamily == 'RedHat' {
      $gen_shib_cert_key_cmd = "/etc/shibboleth/keygen.sh -f -u shibd -h ${::fqdn} -y 100 -e https://${::fqdn}/shibboleth -o /etc/shibboleth/"
    }

    if $shibboleth::create_shib_cert {
      exec { "Generate a Shibboleth Certificate and Key for ${::hostname}":
        cwd      => $shibboleth::params::shib_certs_dir,
        command  => $gen_shib_cert_key_cmd,
        unless   => "openssl x509 -noout -in sp-cert.pem -issuer|grep ${::fqdn}",
        provider => 'shell',
        path     => ['/sbin', '/bin', '/usr/sbin', '/usr/bin'];
      }
    } else {
      # PROVIDE YOUR BACKED-UP/CREATED CERTIFICATE & KEY
      staging::file {
        'Get sp-cert.pem':
          source  => $shibboleth::params::shib_cert_source,
          target  => "${shibboleth::params::shib_certs_dir}/sp-cert.pem",
          notify  => Service['shibd'],
          require => Package[$shibboleth::params::shib_package_name];

        'Get sp-key.pem':
          source  => $shibboleth::params::shib_key_source,
          target  => "${shibboleth::params::shib_certs_dir}/sp-key.pem",
          notify  => Service['shibd'],
          require => Package[$shibboleth::params::shib_package_name];
      }

      #      file {
      #        "${shib_certs_dir}/sp-cert.pem":
      #          mode    => '0644',
      #          source  => $shib_cert_source,
      #          notify  => Service['shibd'],
      #          require => Package[$shibboleth::params::shib_package_name];
      #
      #        "${shib_certs_dir}/sp-key.pem":
      #          mode    => '0644',
      #          source  => $shib_key_source,
      #          notify  => Service['shibd'],
      #          require => Package[$shibboleth::params::shib_package_name];
      #      }
    }
  }

  if $::osfamily == 'Debian' {
    # Enable the module

    file { "${shibboleth::params::apache_mods_enabled}/shib2.load":
      ensure => 'link',
      notify => Service['shibd'],
      target => "${shibboleth::params::apache_mods_location}/shib2.load";
    }
  }
}
