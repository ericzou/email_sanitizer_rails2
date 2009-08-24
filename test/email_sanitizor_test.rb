require 'test_helper'
require 'email_sanitizor'

class EmailSanitizorTest < ActiveSupport::TestCase
  class MockMessage
     attr_accessor :to
  end
     
  class MockUser 
     attr_accessor :email
  end
   
  class MockUserMailerBase
    class << self
      def method_missing(method_name, *arg)
        m_name = /(^deliver_|^create)(.+)/.match("deliver_send_notification")[2]
        new(m_name, *arg)
      end              
    end
    
    def initialize(method_name, *parameters)
      create!(method_name, *parameters)
    end
    
    def create!(method_name, *parameters)
      self.send(method_name, *parameters)
    end
        
  end
   
  class MockUserMailer < MockUserMailerBase
    
    include EmailSanitizor
    
    def send_notification(*args)
      @recipients  = args[0].email if args[0].respond_to?(:email)
      @recipients  = args[0].to if args[0].respond_to?(:to)
    end
    
    sanitize_email :send_notification
  
  end
  
  test "should sanitize an email" do
    EmailSanitizor.options[:base_email] = "joe@example.com"
    joe = MockUser.new
    joe.email = 'joe@email.com'
    xxx = MockUserMailer.deliver_send_notification(joe)
    assert_equal 'joe+joe_at_email.com@example.com', xxx.instance_variable_get(:@recipients)
  end
  
  test "should sanitize emails" do
     EmailSanitizor.options[:base_email] = "joe@example.com"
     msg = MockMessage.new
     msg.to = "joe@email.com, marry@google.com, jack@example.com"
     xxx = MockUserMailer.deliver_send_notification(msg)
     assert_equal ['joe+joe_at_email.com@example.com', 'joe+marry_at_google.com@example.com', 'joe+jack_at_example.com@example.com'], xxx.instance_variable_get(:@recipients)
   
     msg.to = "joe@email.com marry@google.com jack@example.com"
     xxx = MockUserMailer.deliver_send_notification(msg)
     assert_equal ['joe+joe_at_email.com@example.com', 'joe+marry_at_google.com@example.com', 'joe+jack_at_example.com@example.com'], xxx.instance_variable_get(:@recipients)
  
     msg.to = "joe@email.com,;' marry@google.com,; jack@example.com;'"
     xxx = MockUserMailer.deliver_send_notification(msg)
     assert_equal ['joe+joe_at_email.com@example.com', 'joe+marry_at_google.com@example.com', 'joe+jack_at_example.com@example.com'], xxx.instance_variable_get(:@recipients) 
  end
   
  test "should sanitize emails for create_xxx_methods" do 
    EmailSanitizor.options[:base_email] = "joe@example.com"
    joe = MockUser.new
    joe.email = 'joe@email.com'
    xxx = MockUserMailer.create_send_notification(joe)
    assert_equal 'joe+joe_at_email.com@example.com', xxx.instance_variable_get(:@recipients)
  end

  test  "should not sanitize if emails is excluded" do
     EmailSanitizor.options[:base_email] = "eric@example.com"
     EmailSanitizor.options[:exclude_emails] = ["eric@example.com", "joe@example.com", "bill@billbob.com", "marry@marrysilly.com"]
     msg = MockMessage.new
     msg.to = "eric@example.com, joe@example.com, bill@billbob.com, marry@marrysilly.com"
     xxx = MockUserMailer.deliver_send_notification(msg)
     assert_equal ["eric@example.com", "joe@example.com", "bill@billbob.com", "marry@marrysilly.com"], xxx.instance_variable_get(:@recipients)
  end
   
  # todo 
  # test "should not sanitize emais if domain matches base_email domain" do
  #     EmailSanitizor.options[:base_email] = "joe@example.com"
  #     EmailSanitizor.options[:skip_if_domain_match] = true
  # end
  # 
  # test "should sanitize if emails are Array" do 
  # end  
end

