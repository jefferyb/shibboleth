# == Class: shibboleth::services
#
# This module manages shibboleth services
#
# === Authors
#
# Jeffery Bagirimvano <jeffery.rukundo@gmail.com>
#
# === Copyright
#
# Copyright 2014 Jeffery B.
#

class shibboleth::services {
  service { $shibboleth::params::shib_service_name:
    ensure     => 'running',
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => Package[$shibboleth::params::shib_package_name],
  }

  service { $shibboleth::params::apache_service_name:
    ensure     => 'running',
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => Package[$shibboleth::params::apache_package_name],
  }
}
