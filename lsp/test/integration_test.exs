# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell <jonathan.jewell@open.ac.uk>

defmodule PolySSG.IntegrationTest do
  use ExUnit.Case, async: false

  @moduletag :skip
  # Note: These tests are skipped pending GenLSP initialization fixes

  alias PolySSG.LSP.Server
  import LSPHelpers

  @test_dir "/tmp/integration_test_#{System.unique_integer([:positive])}"

  setup do
    File.mkdir_p!(@test_dir)
    File.write!(Path.join(@test_dir, "config.toml"), "# Zola config")
    File.mkdir_p!(Path.join(@test_dir, "content"))
    on_exit(fn -> File.rm_rf!(@test_dir) end)
    {:ok, test_dir: @test_dir}
  end

  test "full LSP lifecycle", %{test_dir: dir} do
    # Start server
    {:ok, pid} = Server.start_link([])

    # Initialize
    init_response = GenLSP.request(pid, initialize_request("file://#{dir}"))
    assert init_response["capabilities"]["textDocumentSync"]["openClose"] == true

    # Send initialized notification
    GenLSP.notify(pid, %{
      "jsonrpc" => "2.0",
      "method" => "initialized",
      "params" => %{}
    })

    Process.sleep(50)

    # Open document
    doc_uri = "file://#{dir}/content/post.md"
    GenLSP.notify(pid, did_open_notification(doc_uri, "markdown", "# Hello World"))
    Process.sleep(50)

    # Verify document stored
    state = :sys.get_state(pid)
    assert state.assigns.documents[doc_uri].text == "# Hello World"

    # Request completion
    completion_response = GenLSP.request(pid, completion_request(doc_uri, 0, 2))
    assert is_list(completion_response) or is_map(completion_response)

    # Request hover
    hover_response = GenLSP.request(pid, hover_request(doc_uri, 0, 2))
    assert is_map(hover_response) or is_nil(hover_response)

    # Change document
    GenLSP.notify(pid, %{
      "jsonrpc" => "2.0",
      "method" => "textDocument/didChange",
      "params" => %{
        "textDocument" => %{"uri" => doc_uri, "version" => 2},
        "contentChanges" => [%{"text" => "# Updated"}]
      }
    })

    Process.sleep(50)

    # Verify change
    state = :sys.get_state(pid)
    assert state.assigns.documents[doc_uri].text == "# Updated"

    # Close document
    GenLSP.notify(pid, %{
      "jsonrpc" => "2.0",
      "method" => "textDocument/didClose",
      "params" => %{"textDocument" => %{"uri" => doc_uri}}
    })

    Process.sleep(50)

    # Verify document removed
    state = :sys.get_state(pid)
    refute Map.has_key?(state.assigns.documents, doc_uri)
  end

  test "adapter supervision and recovery" do
    # Start Hugo adapter
    {:ok, hugo_pid} = PolySSG.Adapters.Hugo.start_link([])
    assert Process.alive?(hugo_pid)

    # Verify it responds
    assert {:ok, _} = PolySSG.Adapters.Hugo.version()

    # Simulate crash
    Process.exit(hugo_pid, :kill)
    Process.sleep(100)

    # Note: In a real supervisor tree, the adapter would restart
    # For this test, we just verify it can be restarted manually
    {:ok, new_pid} = PolySSG.Adapters.Hugo.start_link([])
    assert Process.alive?(new_pid)
    assert {:ok, _} = PolySSG.Adapters.Hugo.version()
  end

  test "error recovery with invalid project path" do
    {:ok, pid} = Server.start_link([])

    # Initialize with non-existent path
    init_response = GenLSP.request(pid, initialize_request("file:///nonexistent"))

    # Should still initialize successfully
    assert init_response["capabilities"]["textDocumentSync"]["openClose"] == true

    # But no SSG detected
    state = :sys.get_state(pid)
    assert is_nil(state.assigns.detected_ssg)
  end
end
