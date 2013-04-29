include apt::update
package { ['bundler', 'puppet', 'git', 'rake']:
	ensure => 'installed',
	require => Exec['apt::update']
}
->
exec { 'bundle install --deployment':
	path => $path,
	cwd => '/vagrant',
	creates => '/vagrant/vendor/bundle'
}

class { 'locale':}
->
class { 'postgresql':
	charset => 'UTF-8',
	locale => 'en_US.UTF-8'
}->
class { 'postgresql::server':
	config_hash => {
		# Allow logins from everywhere - don't do this in production, please
		'listen_addresses'           => '*',
		'ip_mask_deny_postgres_user' => '0.0.0.0/32',
		'ip_mask_allow_all_users'    => '0.0.0.0/0',
		'postgres_password'          => postgresql_password('postgres', 'vagrant')
	}
}->
class { ['postgresql::contrib', 'postgresql::devel']:
	require => File['postgresql encoding']
}

postgresql::database_user { 'vagrant':
	password_hash => postgresql_password('vagrant', 'vagrant'),
	createdb => true,
	require => File['postgresql encoding']
}->
postgresql::database { 'contractor_dev':
	charset => 'UTF-8',
	locale => 'en_US.UTF-8'
}~>
postgresql_psql { 'vagrant owns contractor_dev':
	unless => "SELECT 1 FROM pg_database JOIN pg_authid ON pg_database.datdba = pg_authid.oid WHERE rolname = 'vagrant' AND datname = 'contractor_dev'",
	command => 'ALTER DATABASE contractor_dev OWNER TO vagrant',
	db => 'postgres'
}

postgresql::database { 'contractor_test':
	charset => 'UTF-8',
	locale => 'en_US.UTF-8',
	require => [Class['postgresql::server'], File['postgresql encoding']]
}~>
postgresql_psql { 'vagrant owns contractor_test':
	unless => "SELECT 1 FROM pg_database JOIN pg_authid ON pg_database.datdba = pg_authid.oid WHERE rolname = 'vagrant' AND datname = 'contractor_test'",
	command => 'ALTER DATABASE contractor_test OWNER TO vagrant',
	db => 'postgres'
}

# Now.. debian configures the pg server with a default encoding of SQL_ASCII... yay. We need to fix this
exec { 'drop cluster':
	command => "pg_dropcluster --stop ${::postgresql::params::version} main",
	path => $::path,
	creates => '/root/.pgsqlunicode',
	require => [Class['postgresql::server'], Class['locale']]
}->
exec { 'create cluster':
	command => "pg_createcluster --locale en_US.UTF-8 --encoding UTF-8 --start ${::postgresql::params::version} main",
	path => $::path,
	creates => '/root/.pgsqlunicode'
}->
file { 'postgresql encoding':
	ensure => 'file',
	path => '/root/.pgsqlunicode',
	owner => 'root',
	group => 'root',
	mode => '0600',
	content => ''
}
