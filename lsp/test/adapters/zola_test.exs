# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell <jonathan.jewell@open.ac.uk>

defmodule PolySSG.Adapters.ZolaTest do
  use ExUnit.Case, async: true

  alias PolySSG.Adapters.Zola

  @test_dir "/tmp/zola_test_#{System.unique_integer([:positive])}"

  setup do
    File.mkdir_p!(@test_dir)
    on_exit(fn -> File.rm_rf!(@test_dir) end)
    {:ok, test_dir: @test_dir}
  end

  describe "detect/1" do
    test "detects Zola project with config.toml", %{test_dir: dir} do
      File.write!(Path.join(dir, "config.toml"), "base_url = 'test'")
      assert {:ok, true} = Zola.detect(dir)
    end

    test "does not detect when config.toml missing", %{test_dir: dir} do
      assert {:ok, false} = Zola.detect(dir)
    end
  end

  describe "version/0" do
    test "returns version string" do
      case Zola.version() do
        {:ok, version} ->
          assert is_binary(version)
          assert String.contains?(version, "zola") or String.match?(version, ~r/\d+\.\d+/)

        {:error, _} ->
          # Zola might not be installed
          assert true
      end
    end
  end

  describe "metadata/0" do
    test "returns correct metadata" do
      meta = Zola.metadata()
      assert meta.name == "Zola"
      assert meta.language == "Rust"
      assert meta.description =~ "fast static site generator"
      assert meta.config_files == ["config.toml"]
      assert "templates/" in meta.template_dirs
    end
  end

  describe "clean/1" do
    test "removes public directory", %{test_dir: dir} do
      public_dir = Path.join(dir, "public")
      File.mkdir_p!(public_dir)
      File.write!(Path.join(public_dir, "index.html"), "test")

      Zola.clean(dir)

      refute File.exists?(public_dir)
    end
  end
end
