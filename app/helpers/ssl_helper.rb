module SslHelper
	require "openssl"

	def self.load_key(key)
		return OpenSSL::PKey::RSA.new key
	end

	def self.generate_key(key_size)
		return OpenSSL::PKey::RSA.new key_size
	end

	def self.load_certificate(pem_certificate)
		OpenSSL::X509::Certificate.new pem_certificate
	end

	# params:
	#   required:
	#     :key_size => bits
	#     :serial => int
	#     :common_name => string
	#     :email => string
	#     :valid_for_days => int
	#   optional:
	#     :country => string
	#     :organization => string
	#     :organization_unit => string (only if :organization is entered)
	#   for CA sign:
	#     :is_ca => true
	#     :issuer => certificate
	#     :issuer_key => private key
	def self.generate_certificate(params)
		key = OpenSSL::PKey::RSA.new params[:key_size]
		cert = OpenSSL::X509::Certificate.new
		cert.version = 2
		cert.serial = params[:serial]
		subject_name = "/CN=#{params[:common_name]}/emailAddress=#{params[:email]}"
		if params.has_key? :country
			subject_name += "/C=#{params[:country]}"
		end

		if params.has_key? :organization
			subject_name += "/O=#{params[:organization]}"
			if params.has_key? :organization_unit
				subject_name += "/OU=#{params[:organization_unit]}"
			end
		end
		cert.subject = OpenSSL::X509::Name.parse subject_name

		if params.has_key? :issuer
			# We're signed by a ca
			issuer_name = params[:issuer].subject
			issuer = params[:issuer]
			issuer_key = params[:issuer_key]
		else
			# It's a self sign
			issuer_name = cert.subject
			issuer = cert
			issuer_key = key
		end

		cert.issuer = issuer_name
		cert.public_key = key.public_key
		cert.not_before = Time.now
		cert.not_after = Time.now + 60 * 60 * 24 * params[:valid_for_days]
		ef = OpenSSL::X509::ExtensionFactory.new
		ef.subject_certificate = cert
		ef.issuer_certificate = issuer

		cert.add_extension(ef.create_extension("subjectKeyIdentifier", "hash", false))
		if params.has_key?(:is_ca) && params[:is_ca]
			# Add the extensions that marks this certificate as a CA
			cert.add_extension(ef.create_extension("basicConstraints", "CA:TRUE", true))
			cert.add_extension(ef.create_extension("keyUsage", "keyCertSign, cRLSign", true))
			cert.add_extension(ef.create_extension("authorityKeyIdentifier", "keyid:always", false))
			cert.add_extension(ef.create_extension("crlDistributionPoints", "URI:" + params[:crl_uri], true))
		else
			# Add the extension that marks this for a digital signature usage
			cert.add_extension(ef.create_extension("keyUsage", "digitalSignature", true))

		end
		cert.sign(issuer_key, OpenSSL::Digest::SHA256.new)

		return { :key => key, :certificate => cert }
	end


	def self.get_crl_revocation_reason_from_code(code)
		code = self.get_crl_reason(code)
		case code
		when 0
			return "Unspecified"
		when 1
			return "Key Compromise"
		when 2
			return "CA Compromise"
		when 3
			return "Affiliation Changed"
		when 4
			return "Superseded"
		when 5
			return "Cessation Of Operation"
		when 6
			return "Certificate Hold"
		# 7 seems to be an invalid code... why, I would love to know
		when 8
			return "Remove From CRL"
		when 9
			return "Privilege Withdrawn"
		when 10
			return "AA Compromise"
		else
			raise ArgumentError, 'Argument is out of range'
		end
	end

	def self.get_crl_reason(reason)
		return reason if reason.is_a? Integer
		case reason
		when :unspecified
			return 0
		when :key_compromise
			return 1
		when :ca_compromise
			return 2
		when :affiliation_changed
			return 3
		when :superseded
			return 4
		when :cessation_of_operation
			return 5
		when :certificate_hold
			return 6
		when :remove_from_crl
			return 8
		when :privilege_withdrawn
			return 9
		when :aa_compromise
			return 10
		else
			raise ArgumentError, 'Argument is out of range'
		end
	end

	# params:
	#   required:
	#     :certificate => certificate
	#     :certificate_key => private key
	#   optional:
	#     :revoked_certs_info => array of {
	#       :serial => int
	#       :revoked_time => time of revocation
	#       :reason => int or symbol - for meaning/acceptable values see get_crl_reason
	#     } - default []
	#     :crl_number => int - default 1
	#     :expires_after_seconds => int - default 3600
	def self.generate_crl(params)
		cert = params[:certificate]
		key = params[:certificate_key]
		revoked_certs_info = params[:revoked_certs_info] or []
		crl_number = params[:crl_number] or 1
		expires_after_seconds = params[:expires_after_seconds] or 3600
		now = Time.now

		crl = OpenSSL::X509::CRL.new
		crl.issuer = cert.subject
		crl.version = 1
		crl.last_update = now
		crl.next_update = now + expires_after_seconds

		# Loop through all the revoked certificates and mark each certificate as revoked
		revoked_certs_info.each do |revoked_cert|
			revoked = OpenSSL::X509::Revoked.new
			revoked.serial = revoked_cert[:serial]
			revoked.time = revoked_cert[:revoked_time]
			reason = self.get_crl_reason(revoked_cert[:reason])
			revoked_reason = OpenSSL::ASN1::Enumerated(reason)
			revoked_ext = OpenSSL::X509::Extension.new("CRLReason", revoked_reason)
			revoked.add_extension(revoked_ext)
			crl.add_revoked(revoked)
		end

		ef = OpenSSL::X509::ExtensionFactory.new
		ef.issuer_certificate = cert
		ef.crl = crl
		crlnum = OpenSSL::ASN1::Integer(crl_number)
		crl.add_extension(OpenSSL::X509::Extension.new("crlNumber", crlnum))

		crl.sign(key, OpenSSL::Digest::SHA256.new)

		return crl
	end
end
