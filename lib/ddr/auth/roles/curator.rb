module Ddr
  module Auth
    module Roles

      class Curator < Role
        configure type: Ddr::Vocab::Roles.Curator

        has_permission :read, :download, :add_children, :edit, :upload, :arrange, :grant
      end

    end
  end
end
