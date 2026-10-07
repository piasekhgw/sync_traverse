module SyncTraverse
  class Railtie < Rails::Railtie
    initializer "sync_traverse.ignore_node_tests" do
      pattern = Rails.root.join("app/nodes/**/*test.rb").to_s

      if Rails.autoloaders.main.nil?
        # Rails 6.x with the classic autoloader (Rails.autoloaders.main is nil): eager loading skips
        # files already recorded as loaded, so mark the node tests that way.
        Dir.glob(pattern) { |file| ActiveSupport::Dependencies.loaded << File.expand_path(file).delete_suffix(".rb") }
      else
        Rails.autoloaders.main.ignore(pattern)
      end
    end
  end
end
