require 'test_helper'
require 'openssl'

class SslHelperTest < ActionView::TestCase
	setup do
		@key_size = 1024
	end

	test "can generate_key and load key" do
		key_pem = SslHelper.generate_key(@key_size).to_pem

		key = SslHelper.load_key key_pem

		assert_equal key_pem, key.to_pem
	end

	def assert_common_cert_attributes(key_and_certificate, config, now)
		# Verify the result
		assert_not_nil key_and_certificate[:key]
		assert_not_nil key_and_certificate[:certificate]

		key = key_and_certificate[:key]
		certificate = key_and_certificate[:certificate]

		# Verify the subject
		subject = OpenSSL::X509::Name.parse "/CN=#{config[:common_name]}/emailAddress=#{config[:email]}"
		assert_equal subject, certificate.subject

		# Verify serial
		assert_equal config[:serial], certificate.serial

		assert now <= certificate.not_before
		assert now + (60*60*24*config[:valid_for_days]) <= certificate.not_after
		# Allow that we're 60 seconds off
		assert now + (60*60*24*config[:valid_for_days])+60 > certificate.not_after

		assert_cert_extension certificate, 'subjectKeyIdentifier', nil, false

		assert certificate.check_private_key(key)
	end

	def assert_cert_extension(cert, oid, value, critical)
		ext = cert.extensions.find {|ext| ext.oid == oid}
		assert_not_nil ext

		unless value.nil?
			assert value, ext.value
		end

		assert_equal critical, ext.critical?
	end

	def assert_crl_attributes(crl, config, now)
		assert_not_nil crl
		assert_equal config[:certificate].subject, crl.issuer
		assert crl.verify(config[:certificate_key])

		assert now <= crl.last_update
		assert now+(config[:expires_after_seconds]) <= crl.next_update
		assert now+(config[:expires_after_seconds])+60 > crl.next_update
		assert_equal 1, crl.version

		assert_equal config[:revoked_certs_info].length, crl.revoked.length

		config[:revoked_certs_info].each do |revoked|
			crl_revoked = crl.revoked.find {|r| r.serial == revoked[:serial] && r.time == revoked[:revoked_time] }
			assert_not_nil crl_revoked
			assert_equal 1, crl_revoked.extensions.length

			ext = crl_revoked.extensions[0]

			assert_equal 'CRLReason', ext.oid
			assert_equal SslHelper.get_crl_revocation_reason_from_code(revoked[:reason]), ext.value
		end
	end

	def self_sign_config()
		config = {}
		config[:key_size] = @key_size
		config[:serial] = 10
		config[:common_name] =  'Test Common Name'
		config[:email] = 'test@test.com'
		config[:valid_for_days] = 10

		return config
	end

	def self_sign_ca_config()
		config_ca = {}
		config_ca[:key_size] = @key_size
		config_ca[:serial] = 10
		config_ca[:common_name] =  'Test CA Common Name'
		config_ca[:email] = 'test_ca@test.com'
		config_ca[:valid_for_days] = 10
		config_ca[:is_ca] = true
		config_ca[:crl_uri] = "http://my-test-crl-uri.com"

		return config_ca
	end

	test "can generate self signed certificate" do
		config = self_sign_config
		# Evaluate the time, right now
		now = Time.at(Time.now.to_i)

		key_and_certificate = SslHelper.generate_certificate config

		assert_common_cert_attributes key_and_certificate, config, now
		key = key_and_certificate[:key]
		certificate = key_and_certificate[:certificate]
		# Verify that the private key we have does in fact match the public key
		# This verifies that this is a self signed certificate
		assert certificate.verify(key)

		# In a self signed certificate we must have 2 extensions
		assert_equal 2, certificate.extensions.length

		assert_cert_extension certificate, 'keyUsage', 'Digital Signature', true
	end

	test "can generate ca certificate" do
		config_ca = self_sign_ca_config

		# Evaluate the time, right now
		now = Time.at(Time.now.to_i)

		key_and_certificate = SslHelper.generate_certificate config_ca

		assert_common_cert_attributes key_and_certificate, config_ca, now
		key = key_and_certificate[:key]
		certificate = key_and_certificate[:certificate]

		# Verify that the private key we have does in fact match the public key
		# This verifies that this is a self signed certificate
		assert certificate.verify(key)

		# Bunch of extensions on ca certs
		assert_equal 5, certificate.extensions.length, "Should have 5 extensions"

		assert_cert_extension certificate, 'basicConstraints', 'CA:TRUE', true
		assert_cert_extension certificate, 'keyUsage', 'keyCertSign, cRLSign', true
		assert_cert_extension certificate, 'authorityKeyIdentifier', 'keyid:always', false
		assert_cert_extension certificate, 'crlDistributionPoints', 'URI:' + config_ca[:crl_uri], true
	end

	# TODO: Test for non self signed certificates and CAs alike. Also test the extended
	# attributes that can be used (organization and organization_unit comes to mind)

	test "can generate an empty crl" do
		config_ca = self_sign_ca_config

		key_and_certificate = SslHelper.generate_certificate config_ca

		now = Time.at(Time.now.to_i)

		config_crl = {}
		config_crl[:certificate] = key_and_certificate[:certificate]
		config_crl[:certificate_key] = key_and_certificate[:key]
		config_crl[:crl_number] = 1
		config_crl[:expires_after_seconds] = 3600
		config_crl[:revoked_certs_info] = []

		crl = SslHelper.generate_crl config_crl

		assert_crl_attributes crl, config_crl, now
	end

	test "can generate crl with 1 revoked certificate" do
		config_ca = self_sign_ca_config

		key_and_certificate = SslHelper.generate_certificate config_ca

		now = Time.at(Time.now.to_i)

		config_crl = {}
		config_crl[:certificate] = key_and_certificate[:certificate]
		config_crl[:certificate_key] = key_and_certificate[:key]
		config_crl[:crl_number] = 1
		config_crl[:expires_after_seconds] = 3600
		config_crl[:revoked_certs_info] = [{:serial => 1, :revoked_time => Time.at(Time.now.to_i), :reason => 0}]

		crl = SslHelper.generate_crl config_crl

		assert_crl_attributes crl, config_crl, now
	end

	test "can generate crl with 2 revoked certificates" do
		config_ca = self_sign_ca_config

		key_and_certificate = SslHelper.generate_certificate config_ca

		now = Time.at(Time.now.to_i)

		config_crl = {}
		config_crl[:certificate] = key_and_certificate[:certificate]
		config_crl[:certificate_key] = key_and_certificate[:key]
		config_crl[:crl_number] = 2
		config_crl[:expires_after_seconds] = 3600
		config_crl[:revoked_certs_info] = [
			{:serial => 1, :revoked_time => Time.at(Time.now.to_i), :reason => :unspecified},
			{:serial => 2, :revoked_time => Time.at(Time.now.to_i), :reason => 1}
		]

		crl = SslHelper.generate_crl config_crl

		assert_crl_attributes crl, config_crl, now
	end
end
