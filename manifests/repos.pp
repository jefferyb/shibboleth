# == Class: shibboleth::repos
#
# To manage Shibboleth's Repos.
#
# === Authors
#
# Jeffery Bagirimvano <jeffery.rukundo@gmail.com>
#
# === Copyright
#
# Copyright 2014 Jeffery B.
#

define shibboleth::repos {
  case $::osfamily {
    'Debian' : {

    }
    'RedHat' : {
      case $::operatingsystem {
        'CentOS' : {
          case $::operatingsystemmajrelease {
            '5'     : {
              $yum_repository_url = 'http://download.opensuse.org/repositories/security://shibboleth/CentOS_5/security:shibboleth.repo'
            }
            '6'     : {
              $yum_repository_url = 'http://download.opensuse.org/repositories/security://shibboleth/CentOS_CentOS-6/security:shibboleth.repo'
            }
            '7'     : {
              $yum_repository_url = 'http://download.opensuse.org/repositories/security://shibboleth/CentOS_7/security:shibboleth.repo'
            }
            default : {
              fail("The shibboleth Puppet module does not support ${::operatingsystemmajrelease} family")
            }
          }
        }
        'Redhat' : {
          case $::operatingsystemmajrelease {
            '5'     : {
              $yum_repository_url = 'http://download.opensuse.org/repositories/security://shibboleth/RHEL_5/security:shibboleth.repo'
            }
            '6'     : {
              $yum_repository_url = 'http://download.opensuse.org/repositories/security://shibboleth/RHEL_6/security:shibboleth.repo'
            }
            '7'     : {
              $yum_repository_url = 'http://download.opensuse.org/repositories/security://shibboleth/CentOS_7/security:shibboleth.repo'
            }
            default : {
              fail("The shibboleth Puppet module does not support ${::operatingsystemmajrelease} family")
            }
          }
        }
      }

      exec { 'Add yum repository':
        command => "wget ${yum_repository_url} -P /etc/yum.repos.d",
        creates => '/etc/yum.repos.d/security:shibboleth.repo',
        path    => ['/sbin', '/bin', '/usr/sbin', '/usr/bin'];
      }
    }
    default  : {
      fail("The shibboleth Puppet module does not support ${::osfamily} family of operating systems")
    }
  }
}
