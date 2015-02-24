# == Class: shibboleth::setup_apache
#
# To manage Apache for Shibboleth.
#
# === Authors
#
# Jeffery Bagirimvano <jeffery.rukundo@gmail.com>
#
# === Copyright
#
# Copyright 2014 Jeffery B.
#

class shibboleth::setup_apache {
  if $shibboleth::configure_apache {
    # In case you have another module to manage $apache_package_name,
    # you can turn this off and won't cause conflicts.
    if $shibboleth::install_apache_pkg {
      # Install Apache
      package { $shibboleth::params::apache_package_name: ensure => installed, }
    }

    # Configure Apache Config file...
    file_line {
      'Set ServerAdmin':
        path    => $shibboleth::params::apache_conf_file,
        line    => "ServerAdmin ${shibboleth::admin}",
        match   => '^ServerAdmin.*$',
        notify  => Service[$shibboleth::params::apache_service_name],
        require => Package[$shibboleth::params::apache_package_name];

      'Set ServerName':
        path    => $shibboleth::params::apache_conf_file,
        line    => " ServerName ${::fqdn}:80",
        match   => '(.ServerName) (.*):80',
        notify  => Service[$shibboleth::params::apache_service_name],
        require => Package[$shibboleth::params::apache_package_name];

      'Set DocumentRoot':
        path    => $shibboleth::params::apache_conf_file,
        line    => "DocumentRoot ${shibboleth::apache_DocumentRoot}",
        match   => '^DocumentRoot.*$',
        notify  => Service[$shibboleth::params::apache_service_name],
        require => Package[$shibboleth::params::apache_package_name];

      'Set UseCanonicalName':
        path    => $shibboleth::params::apache_conf_file,
        line    => 'UseCanonicalName On',
        match   => '^UseCanonicalName*',
        notify  => Service[$shibboleth::params::apache_service_name],
        require => Package[$shibboleth::params::apache_package_name];
    }

    # To forward ${shibboleth::session_location} requests to Tomcat
    if $shibboleth::setup_proxy_ajp {
      # LoadModule proxy_ajp_module is being loaded from proxy_ajp.cof file
      # So, we're going to comment it out of $apache_conf_file
      file_line { 'Comment out LoadModule proxy_ajp_module':
        path    => $shibboleth::params::apache_conf_file,
        line    => '#LoadModule proxy_ajp_module modules/mod_proxy_ajp.so',
        match   => '(LoadModule proxy_ajp_module.*)',
        require => Package[$shibboleth::params::apache_package_name];
      }

      file { 'proxy_ajp.conf File':
        ensure  => 'present',
        path    => "${shibboleth::params::apache_mods_location}/proxy_ajp.conf",
        content => template('shibboleth/proxy_ajp.conf.erb'),
        notify  => Service[$shibboleth::params::apache_service_name],
        require => Package[$shibboleth::params::apache_package_name];
      }

      if $::osfamily == 'Debian' {
        # Enable the module
        file { "${shibboleth::params::apache_mods_enabled}/proxy_ajp.conf":
          ensure => 'link',
          notify => Service['shibd'],
          target => "${shibboleth::params::apache_mods_location}/proxy_ajp.conf";
        }
      }
    }
  }
}
