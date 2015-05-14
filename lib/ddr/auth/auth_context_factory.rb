module Ddr::Auth
  class AuthContextFactory

    private_class_method :new

    def self.call(user = nil, env = nil)
      if env
        WebAuthContext.new(user, env)
      else
        DetachedAuthContext.new(user)
      end
    end

  end
end
