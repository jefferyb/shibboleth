# == Class: shibboleth
#
# This module manages shibboleth
# This is a spin off from Aethylred/shibboleth modules but re-wrote it
# mainly to work with my other module, jefferyb/kualicoeus
#
# === Authors
#
# Jeffery Bagirimvano <jeffery.rukundo@gmail.com>
#
# === Copyright
#
# Copyright 2014 Jeffery B.
#

class shibboleth (
  $admin                     = $::shibboleth::params::admin,
  $hostname                  = $::shibboleth::params::hostname,
  # Shibboleth2.xml Settings
  $cookieProps               = $::shibboleth::params::cookieProps,
  $handlerSSL                = true,
  $discoveryURL              = undef,
  $idpURL                    = undef,
  $discovery_protocol        = $::shibboleth::params::discovery_protocol,
  $ecp_support               = false,
  $provider_type             = 'XML',
  $provider_uri,
  $backingFileName           = inline_template("<%= provider_uri.split('/').last  %>"),
  $provider_reload_interval  = '7200',
  $change_attribute_map_file = false,
  $attribute_map_source      = $::shibboleth::params::attribute_map_source,
  $sp_cert                   = $::shibboleth::params::sp_cert,
  $bin_dir                   = $::shibboleth::params::bin_dir,
  $session_location          = undef, # Used in shib.conf
  # mod_ssl settings
  $configure_mod_ssl         = true,
  $install_mod_ssl_pkg       = true,
  $manage_ssl_certificate    = true,
  $key_cert_source           = $::shibboleth::params::key_cert_source,
  $csr_cert_source           = $::shibboleth::params::csr_cert_source,
  $incommon_cert_source      = $::shibboleth::params::incommon_cert_source,
  $install_openssl_pkg       = true,
  $create_ssl_cert           = true,
  $sslCertificateChainFile   = false,
  $sslSessionCacheTimeout    = $::shibboleth::params::sslSessionCacheTimeout,
  # Apache settings
  $configure_apache          = true,
  $install_apache_pkg        = true,
  $setup_proxy_ajp           = true,
  $apache_DocumentRoot       = $::shibboleth::params::apache_DocumentRoot,
  # Shibboleth settings
  $shibboleth_conf_dir       = $::shibboleth::params::shibboleth_conf_dir,
  $shibboleth_conf_file      = $::shibboleth::params::shibboleth_conf_file,
  $shib_attribute_map_file   = $::shibboleth::params::sshib_attribute_map_file,
  $setup_AJP13_support       = 'tomcat', # The only option for now is tomcat
  $tomcat_base               = '/opt/apache-tomcat/tomcat6',
  $manage_shib_certificate   = true,
  $shib_key_source           = $::shibboleth::params::shib_key_source,
  $shib_cert_source          = $::shibboleth::params::shib_cert_source,
  $create_shib_cert          = true,
  $enable_metadata_filter    = false,
  $consistent_address        = true) inherits shibboleth::params {

  include shibboleth::services
  include shibboleth::setup_apache
  include shibboleth::setup_mod_ssl
  include shibboleth::setup_shibboleth
  include shibboleth::setup_shibboleth2_xml

  Class['shibboleth::setup_apache'] ->
  Class['shibboleth::setup_mod_ssl'] ->
  Class['shibboleth::setup_shibboleth2_xml'] ->
  Class['shibboleth::setup_shibboleth']

}
