require "minitest/autorun"
require "sync_traverse"

class SyncTraverseVersionTest < Minitest::Test
  def test_version_module_exists
    assert defined?(SyncTraverse)
    assert_equal "0.1.0", SyncTraverse::VERSION
  end
end
