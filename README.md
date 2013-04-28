# contractor #
An open source SSL certificate manager

## Development ##

If you cloned from git, please make sure all submodules are initted and pointing to the right commits:

```bash
git submodule update --init --recursive
```

You can develop on Contractor like any other Rails application. However if you do not want to mess with setting up your own development machine. Utilize [Vagrant](http://www.vagrantup.com). Install Vagrant and Virtualbox on your machine.
Copy `config/database-vagrant.yml` to `config/database.yml`. Then run the following shell commands from the root of your machine:

```bash
vagrant up
vagrant ssh
cd /vagrant
rake db:migrate
script/rails server
```
