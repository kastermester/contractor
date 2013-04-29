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

	test "can generate self signed certificate" do
		config = {}
		config[:key_size] = @key_size
		config[:serial] = 10
		config[:common_name] =  'Test Common Name'
		config[:email] = 'test@test.com'
		config[:valid_for_days] = 10
		key_and_certificate = SslHelper.generate_certificate config

		# Verify the result
		assert_not_nil key_and_certificate[:key]
		assert_not_nil key_and_certificate[:certificate]

		# Verify the subject
		subject = OpenSSL::X509::Name.parse "/CN=#{config[:common_name]}/emailAddress=#{config[:email]}"
		assert_equal subject, key_and_certificate[:certificate].subject

		# Verify serial
		assert_equal config[:serial], key_and_certificate[:certificate].serial

		# Verify that the private key we have does in fact match the public key
		# This verifies that this is a self signed certificate
		assert key_and_certificate[:certificate].verify(key_and_certificate[:key])

		# TODO: Check that the expiration time matches + others
	end
end
