# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.box = "debian/buster64"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
  end

  config.vm.provision "shell", inline: <<-SHELL
    
    #
    # Install dependencies
    #
    DEBIAN_FRONTEND=noninteractive

    apt-get update
    apt-get install -y devscripts equivs
    apt-get install -y postgresql-11
    apt-get install -y postgis
    apt-get install -y postgresql-11-postgis-2.5
    apt-get install -y postgresql-11-postgis-2.5-scripts

    apt-get install -y postgresql-plpython3-11
    apt-get install -y python3-pip

    sudo pip3 install tltk

    cd /vagrant
    mk-build-deps -t 'apt-get -o Debug::pkgProblemResolver=yes --install-recommends -qqy' -i -r debian/control

    #
    # Build the L10N extensions
    #
    make install

    #
    # Create the database (gis)
    #
    sudo -u postgres createuser --superuser --no-createdb --no-createrole maposmatic
    sudo -u postgres createuser -g maposmatic root
    sudo -u postgres createuser -g maposmatic vagrant

    #
    # Deploy the L10N extensions to the database (gis)
    #
    sudo -u postgres createdb --encoding=UTF8 --locale=en_US.UTF-8 --template=template0 gis
    sudo -u postgres psql --dbname=gis --command="CREATE EXTENSION osml10n CASCADE"
    sudo -u postgres psql --dbname=gis --command="CREATE EXTENSION osml10n_thai_transcript CASCADE"

    #
    # Test the L10N extensions in the database (gis)
    #
    cd tests
    ./runtests.sh gis

  SHELL
end
