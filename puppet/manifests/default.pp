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

include postgresql::contrib, postgresql::devel
class { 'locale':}
->
class { 'postgresql::server':
	config_hash => {
		'listen_addresses'           => '*',
		'ip_mask_deny_postgres_user' => '0.0.0.0/0',
    	'ip_mask_allow_all_users'    => '0.0.0.0/0',
    	'postgres_password'          => 'vagrant'
	}
}->
postgresql::database_user { 'vagrant':
	password_hash => postgresql_password('vagrant', 'vagrant')
}->
postgresql::database { 'contractor_dev':
	charset => 'UTF-8',
	locale => 'en_US.UTF-8'
}->
postgresql::database { 'contractor_test':
	charset => 'UTF-8',
	locale => 'en_US.UTF-8'
}->
postgresql::database_grant { 'contractor_dev':
	privilege => 'ALL',
	db => 'contractor_dev',
	role => 'vagrant'
}->
postgresql::database_grant { 'contractor_test':
	privilege => 'ALL',
	db => 'contractor_test',
	role => 'vagrant'
}
# Hard development configs... do not ever do this in a production environment
postgresql::pg_hba_rule { 'open ipv4':
	description => "Opens up the database on all IPv4 addresses",
	type => 'host',
	database => 'all',
	user => 'all',
	address => '0.0.0.0/24',
	auth_method => 'md5',
}->
postgresql::pg_hba_rule { 'open ipv6':
	description => "Opens up the database on all IPv6 addresses",
	type => 'host',
	database => 'all',
	user => 'all',
	address => '::/0',
	auth_method => 'md5',
}
