module SyncTraverse
  class Railtie < Rails::Railtie
    initializer "sync_traverse.ignore_node_tests" do
      Rails.autoloaders.main.ignore(Rails.root.join("app/nodes/**/*test.rb"))
    end
  end
end
