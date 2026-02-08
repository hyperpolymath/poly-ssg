# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell <jonathan.jewell@open.ac.uk>

defmodule PolySSG.Adapters.MdbookTest do
  use ExUnit.Case, async: true

  alias PolySSG.Adapters.Mdbook

  @test_dir "/tmp/mdbook_test_#{System.unique_integer([:positive])}"

  setup do
    File.mkdir_p!(@test_dir)
    on_exit(fn -> File.rm_rf!(@test_dir) end)
    {:ok, test_dir: @test_dir}
  end

  describe "detect/1" do
    test "detects mdBook project with book.toml", %{test_dir: dir} do
      File.write!(Path.join(dir, "book.toml"), "[book]\ntitle = 'Test'")
      assert {:ok, true} = Mdbook.detect(dir)
    end

    test "returns false when book.toml missing", %{test_dir: dir} do
      assert {:ok, false} = Mdbook.detect(dir)
    end
  end

  describe "version/0" do
    test "returns version string or error" do
      case Mdbook.version() do
        {:ok, version} ->
          assert is_binary(version)
          assert String.contains?(version, "mdbook") or String.contains?(version, "mdBook") or
                   String.match?(version, ~r/\d+\.\d+/)

        {:error, _} ->
          # mdbook might not be installed
          assert true
      end
    end
  end

  describe "metadata/0" do
    test "returns correct metadata" do
      meta = Mdbook.metadata()
      assert meta.name == "mdBook"
      assert meta.language == "Rust"
      assert meta.config_files == ["book.toml"]
      assert "src/" in meta.template_dirs
    end
  end

  describe "clean/1" do
    test "removes book directory", %{test_dir: dir} do
      book_dir = Path.join(dir, "book")
      File.mkdir_p!(book_dir)
      File.write!(Path.join(book_dir, "index.html"), "test")

      Mdbook.clean(dir)

      refute File.exists?(book_dir)
    end
  end
end
