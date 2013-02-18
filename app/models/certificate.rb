class Certificate < ActiveRecord::Base
  attr_accessible :created_at, :updated_at, :name, :pem_certificate, :pem_private_key, :common_name, :email, :serial, :child_last_serial, :expires, :issuer_certificate, :issued_certificates
  attr_protected :pem_certificate, :pem_private_key, :serial, :child_last_serial, :issued_certificates
  belongs_to :issuer_certificate, 
  	:class_name => "Certificate"
  	
  has_many :issued_certificates,
  	:inverse_of => :issuer_certificate,
  	:class_name => "Certificate",
  	:foreign_key => "issuer_certificate_id"

  after_initialize :init

  def init
  	self.is_ca ||= false
  	self.expires ||= Time.now + 60*60*24*365
  end

  def full_certificate
  	puts self.pem_certificate.inspect
  	cert = self.pem_certificate

  	if self.issuer_certificate
  		cert += self.issuer_certificate.full_certificate
  	end

  	return cert
  end

end
