require "test_helper"

module SyncTraverse
  class ConfigTest < Minitest::Test
    def test_resolves_fixed_paths_relative_to_root_dir
      config = Config.new("/project")

      assert_equal(
        ["/project/app/actions", "/project/test/actions", "/project/app/flows", "/project/test/flows"],
        [config.actions_dir, config.action_tests_dir, config.flows_dir, config.flow_tests_dir]
      )
    end
  end
end
