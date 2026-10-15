require "test_helper"

module SyncTraverse
  module Tools
    class BaseTest < SyncTraverse::TestCase
      def test_write_file_replaces_content_and_leaves_no_temporary_file
        path = File.join(flows_dir, "orders", "draft.json")
        Base.send(:write_file, path, "old")

        Base.send(:write_file, path, "new")

        assert_equal "new", File.read(path)
        assert_equal %w[draft.json], Dir.children(File.dirname(path))
      end

      def test_write_file_removes_temporary_file_when_rename_fails
        path = File.join(flows_dir, "orders", "draft.json")
        FileUtils.mkdir_p(File.join(path, "occupied"))

        assert_raises(SystemCallError) { Base.send(:write_file, path, "new") }

        assert_equal %w[draft.json], Dir.children(File.dirname(path))
      end
    end
  end
end
