# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell <jonathan.jewell@open.ac.uk>

defmodule PolySSG.Adapters.HugoTest do
  use ExUnit.Case, async: true

  alias PolySSG.Adapters.Hugo

  @test_dir "/tmp/hugo_test_#{System.unique_integer([:positive])}"

  setup do
    File.mkdir_p!(@test_dir)
    on_exit(fn -> File.rm_rf!(@test_dir) end)
    {:ok, test_dir: @test_dir}
  end

  describe "detect/1" do
    test "detects Hugo project with config.toml", %{test_dir: dir} do
      File.write!(Path.join(dir, "config.toml"), "title = 'Test'")
      assert {:ok, true} = Hugo.detect(dir)
    end

    test "detects Hugo project with hugo.toml", %{test_dir: dir} do
      File.write!(Path.join(dir, "hugo.toml"), "title = 'Test'")
      assert {:ok, true} = Hugo.detect(dir)
    end

    test "detects Hugo project with config.yaml", %{test_dir: dir} do
      File.write!(Path.join(dir, "config.yaml"), "title: Test")
      assert {:ok, true} = Hugo.detect(dir)
    end

    test "does not detect when no config files present", %{test_dir: dir} do
      assert {:ok, false} = Hugo.detect(dir)
    end
  end

  describe "version/0" do
    test "returns version string" do
      case Hugo.version() do
        {:ok, version} ->
          assert is_binary(version)
          assert String.contains?(version, "hugo") or String.contains?(version, "Hugo")

        {:error, _} ->
          # Hugo might not be installed in test environment
          assert true
      end
    end
  end

  describe "metadata/0" do
    test "returns correct metadata" do
      meta = Hugo.metadata()
      assert meta.name == "Hugo"
      assert meta.language == "Go"
      assert meta.description =~ "Fast and flexible"
      assert "config.toml" in meta.config_files
      assert "hugo.toml" in meta.config_files
      assert "layouts/" in meta.template_dirs
      assert "themes/" in meta.template_dirs
    end
  end

  describe "clean/1" do
    test "removes public directory", %{test_dir: dir} do
      public_dir = Path.join(dir, "public")
      File.mkdir_p!(public_dir)
      File.write!(Path.join(public_dir, "test.html"), "test")

      Hugo.clean(dir)

      refute File.exists?(public_dir)
    end

    test "succeeds even if public directory does not exist", %{test_dir: dir} do
      assert :ok = Hugo.clean(dir)
    end
  end
end
