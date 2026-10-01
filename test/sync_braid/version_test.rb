require "minitest/autorun"
require "sync_braid"

class SyncBraidVersionTest < Minitest::Test
  def test_version_module_exists
    assert defined?(SyncBraid)
    assert_equal "0.1.0", SyncBraid::VERSION
  end
end
