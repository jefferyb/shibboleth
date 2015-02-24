require 'spec_helper'

describe 'shibboleth', :type => :class do

  describe "Shibboleth class with basic parameters, basic test" do
#    let(:params) { { } }
    let :params do
      {
        :session_location => 'kc-srv',
	:sslSessionCacheTimeout => '1200',
	:idpURL => 'https://idp.testshib.org/idp/shibboleth',
	:provider_uri             => 'http://www.testshib.org/metadata/testshib-providers.xml',
	:backingFileName        => 'testshib-two-idp-metadata.xml',
	:provider_reload_interval => '600',
      }
    end

    let :facts do
      {
        :osfamily => 'Debian', :operatingsystem => 'Ubuntu', :lsbmajdistrelease => '14', :lsbdistcodename => 'trusty', :kernel => 'Linux'
      }
    end
	it { should contain_class('shibboleth') }


#      it {
#        should contain_package('libapache2-mod-shib2')
#        should contain_service('shibd')
#      }
  end
end

