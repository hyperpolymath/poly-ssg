# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell <jonathan.jewell@open.ac.uk>

defmodule PolySSG.Adapters.HakyllTest do
  use ExUnit.Case, async: true

  alias PolySSG.Adapters.Hakyll

  @test_dir "/tmp/hakyll_test_#{System.unique_integer([:positive])}"

  setup do
    File.mkdir_p!(@test_dir)
    on_exit(fn -> File.rm_rf!(@test_dir) end)
    {:ok, test_dir: @test_dir}
  end

  describe "detect/1" do
    test "detects Hakyll project with site.hs", %{test_dir: dir} do
      File.write!(Path.join(dir, "site.hs"), "-- Hakyll config")
      assert {:ok, true} = Hakyll.detect(dir)
    end

    test "detects Hakyll project with .cabal file", %{test_dir: dir} do
      File.write!(Path.join(dir, "mysite.cabal"), "name: mysite")
      assert {:ok, true} = Hakyll.detect(dir)
    end

    test "returns false when neither site.hs nor cabal file present", %{test_dir: dir} do
      assert {:ok, false} = Hakyll.detect(dir)
    end
  end

  describe "version/0" do
    test "returns version or unknown" do
      assert {:ok, version} = Hakyll.version()
      assert is_binary(version)
    end
  end

  describe "metadata/0" do
    test "returns correct metadata" do
      meta = Hakyll.metadata()
      assert meta.name == "Hakyll"
      assert meta.language == "Haskell"
      assert "site.hs" in meta.config_files
      assert "templates/" in meta.template_dirs
    end
  end

  describe "clean/1" do
    test "returns error when site binary missing", %{test_dir: dir} do
      assert {:error, _msg} = Hakyll.clean(dir)
    end
  end
end
