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
		cert.not_after = Time.now + 60 * 60 * 25 * params[:valid_for_days]
		ef = OpenSSL::X509::ExtensionFactory.new
		ef.subject_certificate = cert
		ef.issuer_certificate = issuer

		cert.add_extension(ef.create_extension("subjectKeyIdentifier", "hash", false))
		if params.has_key? :is_ca && params[:is_ca]
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
end
