# == Class: shibboleth::setup_shibboleth2_xml
#
# Class to setup shibboleth2.xml
#
# === Authors
#
# Jeffery Bagirimvano <jeffery.rukundo@gmail.com>
#
# === Copyright
#
# Copyright 2014 Jeffery B.
#

class shibboleth::setup_shibboleth2_xml {
  $shibboleth2_xml = "${shibboleth::params::shibboleth_conf_dir}/${shibboleth::params::shibboleth_conf_file}"

  file { 'shibboleth_conf_dir':
    ensure  => 'directory',
    path    => $shibboleth::params::shibboleth_conf_dir,
    require => Package[$shibboleth::params::shib_package_name]
  }

  file { 'shibboleth_config_file':
    ensure  => 'file',
    path    => $shibboleth2_xml,
    replace => false,
    require => [Package[$shibboleth::params::shib_package_name], File['shibboleth_conf_dir']],
  }

  augeas { 'Set hostname Attribute':
    lens    => 'Xml.lns',
    incl    => $shibboleth2_xml,
    context => "/files${shibboleth2_xml}/SPConfig/ApplicationDefaults",
    changes => [
      "set #attribute/entityID https://${::fqdn}/shibboleth",
      "set Sessions/#attribute/cookieProps ${shibboleth::cookieProps}",
      ],
    notify  => Service[$shibboleth::params::apache_service_name, 'shibd'],
    require => Package[$shibboleth::params::shib_package_name],
  }

  augeas { 'Set handlerSSL Attribute':
    lens    => 'Xml.lns',
    incl    => $shibboleth2_xml,
    context => "/files${shibboleth2_xml}/SPConfig/ApplicationDefaults",
    changes => ["set Sessions/#attribute/handlerSSL ${shibboleth::handlerSSL}",],
    notify  => Service[$shibboleth::params::apache_service_name, 'shibd'],
    require => Package[$shibboleth::params::shib_package_name],
  }

  if $shibboleth::discoveryURL and $shibboleth::idpURL {
    err('Shibboleth must have one of discoveryURL or idpURL set, not both.')
  } elsif !$shibboleth::discoveryURL and !$shibboleth::idpURL {
    err('Shibboleth must have one of discoveryURL or idpURL set, not neither.')
  } else {
    if $shibboleth::idpURL {
      $entityID_aug = "set SSO/#attribute/entityID ${shibboleth::idpURL}"
    } else {
      $entityID_aug = 'rm SSO/#attribute/entityID'
    }

    if $shibboleth::discoveryURL {
      $discoveryURL_aug = "set SSO/#attribute/discoveryURL ${shibboleth::discoveryURL}"
    } else {
      $discoveryURL_aug = 'rm SSO/#attribute/discoveryURL'
    }

    augeas { 'Set SSO Attributes':
      lens    => 'Xml.lns',
      incl    => $shibboleth2_xml,
      context => "/files${shibboleth2_xml}/SPConfig/ApplicationDefaults/Sessions",
      changes => [
        $entityID_aug,
        $discoveryURL_aug,
        "set SSO/#attribute/discoveryProtocol ${shibboleth::discovery_protocol}",
        "set SSO/#attribute/ECP ${shibboleth::ecp_support}",
        ],
      notify  => Service[$shibboleth::params::apache_service_name, 'shibd'],
      require => Package[$shibboleth::params::shib_package_name],
    }
  }

  # This puts the MetadataProvider entry in the 'right' place
  augeas { 'Create MetadataProvider Entry':
    lens    => 'Xml.lns',
    incl    => $shibboleth2_xml,
    context => "/files${shibboleth2_xml}/SPConfig/ApplicationDefaults",
    changes => ['ins MetadataProvider after Errors',],
    onlyif  => 'match MetadataProvider/#attribute/uri size == 0',
    notify  => Service[$shibboleth::params::apache_service_name, 'shibd'],
    require => Package[$shibboleth::params::shib_package_name],
  }

  # This will update the attributes and child nodes if they change
  augeas { 'Update MetadataProvider Attributes':
    lens    => 'Xml.lns',
    incl    => $shibboleth2_xml,
    context => "/files${shibboleth2_xml}/SPConfig/ApplicationDefaults",
    changes => [
      "set MetadataProvider/#attribute/type ${shibboleth::provider_type}",
      "set MetadataProvider/#attribute/uri ${shibboleth::provider_uri}",
      "set MetadataProvider/#attribute/backingFilePath ${shibboleth::backingFileName}",
      "set MetadataProvider/#attribute/reloadInterval ${shibboleth::provider_reload_interval}",
      ],
    notify  => Service[$shibboleth::params::apache_service_name, 'shibd'],
    require => [Package[$shibboleth::params::shib_package_name], Augeas['Create MetadataProvider Entry']],
  }

  if $shibboleth::change_attribute_map_file {
    $attribute_map = "${shibboleth::shibboleth_conf_dir}/${$shibboleth::shib_attribute_map_file}"

    # Download the attribute map
    staging::file { $attribute_map: source => $shibboleth::attribute_map_source, }

    # Make sure the shibboleth config is pointing at the attribute map
    augeas { 'Set Attribute Map Path':
      lens    => 'Xml.lns',
      incl    => $shibboleth2_xml,
      context => "/files${shibboleth2_xml}/SPConfig/ApplicationDefaults",
      changes => ["set AttributeExtractor/#attribute/path ${$shibboleth::shib_attribute_map_file}",],
      notify  => Service[$shibboleth::params::apache_service_name, 'shibd'],
      require => [Package[$shibboleth::params::shib_package_name], Staging::File[$attribute_map]]
    }
  }
}
