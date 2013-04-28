class locale {
	file { '/etc/locale.gen':
		ensure => 'file',
		owner => 'root',
		group => 'root',
		mode => '0644',
		source => 'puppet:///modules/locale/locale.gen',
		notify => Exec['regen locales']
	}

	exec { 'regen locales':
		command => '/usr/sbin/locale-gen',
		user => 'root',
		path => $path,
		refreshonly => true
	}
}
