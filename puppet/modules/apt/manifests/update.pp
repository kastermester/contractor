class apt::update {
	exec { 'apt::update':
		path => $path,
		command => 'apt-get update'
	}
}
