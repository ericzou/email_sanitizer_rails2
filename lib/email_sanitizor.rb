# EmailSanitizor
# EmailSanitizor.options[:base_mail] => "joe@example.com"

module  EmailSanitizor
  
  def self.options
    @options ||= {
      :base_email => 'default@example.com',
      :exclud_emails =>[]
    }  
  end
  
  
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  
  module ClassMethods
    
    def sanitize_email(*syms)
      syms.each do |sym|
          self.class_eval do
            alias_method "org_#{sym}", sym
            define_method sym do |*args|
              __send__("org_#{sym}", *args)
              e = instance_variable_get(:@recipients)
              instance_variable_set(:@recipients, sanitize(e, :base_email => EmailSanitizor.options[:base_email], :exclude_emails => EmailSanitizor.options[:exclude_emails]) )
            end
            
            private
            
            def sanitize(emails_str, opt={})
              emails = emails_str.split(/[,;'\s]+/)
              base_email = opt[:base_email]
              excluded_emails = opt[:exclude_emails]
              base_head, base_tail = base_email.split("@")
              sanitized_emails = []
              emails.each_with_index do |email, index|
                next if excluded_emails.include?(email)
                h, t = email.split("@")
                emails[index] = "#{base_head}+#{h}_at_#{t}@#{base_tail}"
              end
              emails.size > 1 ? emails : emails[0]
            end
          end
      end
    end
  end
end