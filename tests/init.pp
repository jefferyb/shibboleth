#
# Using jefferyb/shibboleth module to install & configure shibboleth
#

class { '::shibboleth':
  # Set discoveryProtocol SSO Attributes
  idpURL                   => 'https://idp.testshib.org/idp/shibboleth',
  # Session location to secure
  session_location         => 'secure',
  # Metadata
  provider_uri             => 'http://www.testshib.org/metadata/testshib-providers.xml',
  backingFileName          => 'providers.xml',
  provider_reload_interval => '600',
}
