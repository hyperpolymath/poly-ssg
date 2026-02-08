# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell <jonathan.jewell@open.ac.uk>

defmodule PolySSG.Adapters.JekyllTest do
  use ExUnit.Case, async: true

  alias PolySSG.Adapters.Jekyll

  @test_dir "/tmp/jekyll_test_#{System.unique_integer([:positive])}"

  setup do
    File.mkdir_p!(@test_dir)
    on_exit(fn -> File.rm_rf!(@test_dir) end)
    {:ok, test_dir: @test_dir}
  end

  describe "detect/1" do
    test "detects Jekyll project with _config.yml", %{test_dir: dir} do
      File.write!(Path.join(dir, "_config.yml"), "title: Test")
      assert {:ok, true} = Jekyll.detect(dir)
    end

    test "detects Jekyll project with Gemfile containing jekyll", %{test_dir: dir} do
      File.write!(Path.join(dir, "Gemfile"), ~s(gem "jekyll"))
      assert {:ok, true} = Jekyll.detect(dir)
    end

    test "returns false when neither config nor Gemfile present", %{test_dir: dir} do
      assert {:ok, false} = Jekyll.detect(dir)
    end
  end

  describe "version/0" do
    test "returns version string or error" do
      case Jekyll.version() do
        {:ok, version} ->
          assert is_binary(version)
          assert String.contains?(version, "jekyll") or String.match?(version, ~r/\d+\.\d+/)

        {:error, _} ->
          # Jekyll might not be installed
          assert true
      end
    end
  end

  describe "metadata/0" do
    test "returns correct metadata" do
      meta = Jekyll.metadata()
      assert meta.name == "Jekyll"
      assert meta.language == "Ruby"
      assert "_config.yml" in meta.config_files
      assert "_layouts/" in meta.template_dirs
    end
  end

  describe "clean/1" do
    test "removes _site directory", %{test_dir: dir} do
      site_dir = Path.join(dir, "_site")
      File.mkdir_p!(site_dir)
      File.write!(Path.join(site_dir, "index.html"), "test")

      Jekyll.clean(dir)

      refute File.exists?(site_dir)
    end
  end
end
