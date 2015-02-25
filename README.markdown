# Shibboleth

This module manages shibboleth. It started out as a spin off from Aethylred/shibboleth's module but ended up re-writting it. I created this module mainly to work with my other module, jefferyb/kualicoeus but looking into expanding it to with other applications (It should work with any apache/tomcat web server/servlet)

## Example Usage
The following is an example installation:
```puppet
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
```

## Parameters for shibboleth

- `admin`	Sets the Shibboleth administrator's email address, defaults to `root@localhost`
- `hostname`	Sets the host name to be used in the Shibboleth configuration, defaults to `fqdn`

##### Shibboleth2.xml Settings
- `cookieProps` You should also set cookieProps to "https" for SSL-only sites. Defaults to `https`
- `handlerSSL` Using handlerSSL="true", the default, will force the protocol to be https. Defaults to `true`
- `discoveryURL` The URL of the discovery service, is undefined by default
- `idpURL` The URL of a single IDp, is undefined by default

**Note:** Either one of ***discoveryURL*** or ***idpURL*** is required, but not both.

- `discovery_protocol` Sets the discovery protocol for the discovery service provided in the discoveryURL, defaults to `SAMLDS`
- `ecp_support` Sets support for non-web based ECP logins, by default this is `false`
- `provider_type` Sets the metadata provider type, defaults to 'XML'. defaults to `XML`
- `provider_uri` Sets URI for the metadata provider, there is no default and this parameter is required.
- `backingFileName` Sets the name of the metadata backing file, by default this is derived from the `provider_uri`
- `provider_reload_interval` Set's the metadata reload interval in seconds, defaults to "7200"
- `sp_cert` Sets the name of the Shibboleth Service Provider back end certificate, defaults to `sp-cert.pem`
- `bin_dir` Sets the location of the Shibboleth tools (esp. shib-keygen), defaults to `/usr/sbin`
- `session_location` Session location to secure. Defaults to `undef`

###### Parameters for customised attribute_map

- `change_attribute_map_file` Defaults to `false`. Change it do true if you want to `true` if you want to use a customised attribute map downloaded from the provided URI.
- `attribute_map_source` Sets the URI for downloading the Attribute map from. There is no default, and this parameter is required.

##### mod_ssl Settings

- `configure_mod_ssl` Defaults to `true`. Set it to `false` to skip/not use the shibboleth::setup_mod_ssl Class, like if you have your own setup of mod_ssl or because of another module.
- `install_mod_ssl_pkg` Defaults to `true`. Set it to `false` if you're having conflict with other modules or don't want to install the mod_ssl package.
- `manage_ssl_certificate` In case you have another module to manage `$install_openssl_pkg`, you can turn this off by setting to `false` and won't cause conflicts.
- `install_openssl_pkg` Defaults to `true` to install openssl packages.
- `create_ssl_cert` Create new ssl certificates. If set to `false`, then it will use `key_cert_source` and `csr_cert_source` to get certificates. Defaults to `true`
- `key_cert_source` Sets the location of the key cert. Defaults to `puppet:///modules/shibboleth/${::hostname}.key`
- `csr_cert_source` Sets the location of the csr cert. Defaults to `puppet:///modules/shibboleth/${::hostname}.crt`
- `sslCertificateChainFile` Defaults to `false`. Set this to `true` when you get signed certificate and set `incommon_cert_source`
- `incommon_cert_source` Sets the location of your signed certificate. Defaults to `puppet:///modules/shibboleth/${::hostname}.incommon-chain.crt`
- `sslSessionCacheTimeout` Change SSLSessionCacheTimeout in ssl.conf

##### Apache Settings

- `configure_apache` Defaults to `true`. Set it to `false` if you're having conflicts with other apache module.
- `install_apache_pkg` Defaults to `true`. Set it to `false` if you're having conflicts with other package install.
- `setup_proxy_ajp` Used to forward `session_location` requests to Tomcat. Defaults to `true`.
- `apache_DocumentRoot` Defaults to `/var/www/html`

##### Shibboleth Settings

- `shibboleth_conf_dir` Defaults to `/etc/shibboleth`
- `shibboleth_conf_file` Defaults to `shibboleth2.xml`
- `shib_attribute_map_file` Defaults to `attribute-map.xml`
- `setup_AJP13_support` Setup AJP13 support in your servlet container and for now, it's `tomcat`
- `tomcat_base` Defaults to `/opt/apache-tomcat/tomcat6`
- `manage_shib_certificate` This generates a self signed x509 certificate used to secure connections with a Shibboleth Federation registry. If the key is ever lost or overwritten the certificate will have to be re-registered. Defaults to `true`. Set it to `false` if you want them to be deployed from the puppetmaster by setting `shib_key_source` and `shib_cert_source`.
- `shib_key_source` Defaults to `puppet:///modules/shibboleth/${::hostname}.sp-key.pem`
- `shib_cert_source` Defaults to `puppet:///modules/shibboleth/${::hostname}.sp-cert.pem`
- `create_shib_cert` Defaults to `true`.

