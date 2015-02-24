# == Class: shibboleth::params
#
# This class manages shared prameters and variables for the shibboleth module
#
# === Authors
#
# Jeffery Bagirimvano <jeffery.rukundo@gmail.com>
#
# === Copyright
#
# Copyright 2014 Jeffery B.
#

class shibboleth::params {
  $admin = 'root@localhost'
  $hostname = $::fqdn

  # Shibboleth2.xml Settings
  $cookieProps = 'https'
  $discovery_protocol = 'SAMLDS'
  $shib_attribute_map_file = 'attribute-map.xml'
  $attribute_map_source = "puppet:///modules/shibboleth/${::hostname}.${shib_attribute_map_file}"

  $sp_cert = 'sp-cert.pem'
  $bin_dir = '/usr/sbin'
  $sslSessionCacheTimeout = '300' # Used in ssl.conf
  $shib_service_name = 'shibd'

  # OpenSSL Settings
  $openssl_package_name = 'openssl'
  $cert_name = $::hostname
  $country = 'US'
  $state = 'California'
  $locality = 'San Fransisco'
  $organization = 'University Name'
  $unit = 'Department Name'
  $key_cert_source = "puppet:///modules/shibboleth/${::hostname}.key"
  $csr_cert_source = "puppet:///modules/shibboleth/${::hostname}.crt"
  $incommon_cert_source = "puppet:///modules/shibboleth/${::hostname}.incommon-chain.crt"

  # SHIBBOLETH SETTINGS
  $shibboleth_conf_dir = '/etc/shibboleth'
  $shibboleth_conf_file = 'shibboleth2.xml'
  $shib_certs_dir = '/etc/shibboleth'
  $shib_key_source = "puppet:///modules/shibboleth/${::hostname}.sp-key.pem"
  $shib_cert_source = "puppet:///modules/shibboleth/${::hostname}.sp-cert.pem"

  case $::osfamily {
    'Debian' : {
      # Apache Settings
      $apache_package_name = 'apache2'
      $apache_service_name = 'apache2'
      $apache_mods_enabled = '/etc/apache2/mods-enabled'
      $apache_mods_location = '/etc/apache2/mods-available'
      $apache_sites_available = '/etc/apache2/sites-available'
      $apache_sites_enabled = '/etc/apache2/sites-enabled'
      $apache_conf_file = '/etc/apache2/apache2.conf'
      $apache_DocumentRoot = '/var/www/html'

      # mod_ssl
      $mod_ssl_package_name = 'libapache2-mod-shib2'
      $certs_dir = '/etc/ssl/private'
      $ssl_conf_file = '/etc/apache2/sites-available/default-ssl.conf'

      # Shibboleth Settings
      $shib_package_name = 'libapache2-mod-shib2'
    }
    'RedHat' : {
      # Apache Settings
      $apache_package_name = 'httpd'
      $apache_service_name = 'httpd'
      $apache_mods_location = '/etc/httpd/conf.d'
      $apache_conf_file = '/etc/httpd/conf/httpd.conf'
      $apache_DocumentRoot = '/var/www/html'

      # mod_ssl
      $mod_ssl_package_name = 'mod_ssl'
      $certs_dir = '/etc/pki/tls/certs'
      $ssl_conf_file = '/etc/httpd/conf.d/ssl.conf'

      # Shibboleth Settings
      case $::architecture {
        'x86_64'        : { $shib_package_name = 'shibboleth.x86_64' }
        /^(i386|i686)$/ : { $shib_package_name = 'shibboleth' }
        default         : { fail("The shibboleth Puppet module does not support ${::architecture} family") }
      }
    }
    default  : {
      fail("The shibboleth Puppet module does not support ${::osfamily} family of operating systems")
    }
  }
}
