# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell <jonathan.jewell@open.ac.uk>

defmodule PolySSG.Adapters.FranklinTest do
  use ExUnit.Case, async: true

  alias PolySSG.Adapters.Franklin

  @test_dir "/tmp/franklin_test_#{System.unique_integer([:positive])}"

  setup do
    File.mkdir_p!(@test_dir)
    on_exit(fn -> File.rm_rf!(@test_dir) end)
    {:ok, test_dir: @test_dir}
  end

  describe "detect/1" do
    test "detects Franklin project with Project.toml containing Franklin", %{test_dir: dir} do
      File.write!(Path.join(dir, "Project.toml"), """
      [deps]
      Franklin = "0.10"
      """)
      assert {:ok, true} = Franklin.detect(dir)
    end

    test "returns false when Project.toml missing", %{test_dir: dir} do
      assert {:ok, false} = Franklin.detect(dir)
    end

    test "returns false when Project.toml doesn't contain Franklin", %{test_dir: dir} do
      File.write!(Path.join(dir, "Project.toml"), """
      [deps]
      SomeOtherPackage = "1.0"
      """)
      assert {:ok, false} = Franklin.detect(dir)
    end
  end

  describe "version/0" do
    test "returns version string or error" do
      case Franklin.version() do
        {:ok, version} ->
          assert is_binary(version)

        {:error, _} ->
          # Julia might not be installed in test environment
          assert true
      end
    end
  end

  describe "metadata/0" do
    test "returns correct metadata" do
      meta = Franklin.metadata()
      assert meta.name == "Franklin"
      assert meta.language == "Julia"
      assert meta.config_files == ["Project.toml", "config.md"]
    end
  end

  describe "clean/1" do
    test "removes __site directory", %{test_dir: dir} do
      site_dir = Path.join(dir, "__site")
      File.mkdir_p!(site_dir)
      File.write!(Path.join(site_dir, "index.html"), "test")

      Franklin.clean(dir)

      refute File.exists?(site_dir)
    end
  end
end
