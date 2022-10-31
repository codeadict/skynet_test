defmodule Skynet.ApiTest do
  @moduledoc false
  use ExUnit.Case, async: true

  import Skynet.ApiUtils

  alias Skynet.Terminators
  alias Skynet.TerminatorSupervisor

  describe "GET /_health" do
    test "returns application health's response" do
      version = Application.spec(:skynet, :vsn) |> List.to_string()

      conn = make_request(:get, "/_health")

      assert conn.status == 200
      assert Jason.decode!(conn.resp_body) == %{"version" => version}
    end
  end

  describe "POST /terminators" do
    test "creates a new terminator with a provided name" do
      conn = make_request(:post, "/terminators", %{name: "terminator1"})

      assert conn.status == 201
      assert %{"name" => "terminator1", "pid" => pid} = Jason.decode!(conn.resp_body)["data"]
      assert pid in get_child_pids(TerminatorSupervisor)
    end

    test "creates a new random terminator if name is not provided" do
      conn = make_request(:post, "/terminators")

      assert conn.status == 201
      assert %{"name" => _random, "pid" => pid} = Jason.decode!(conn.resp_body)["data"]
      assert pid in get_child_pids(TerminatorSupervisor)
    end
  end

  describe "GET /terminators" do
    test "returns the list of alive terminators" do
      num_terminators = 5

      for n <- 1..num_terminators, do: Terminators.create("T-#{n}")

      conn = make_request(:get, "/terminators")

      assert conn.status == 200

      for n <- 1..num_terminators,
          do: assert(%{"name" => "T-#{n}"} in Jason.decode!(conn.resp_body)["data"])
    end
  end

  describe "DELETE /terminators/:name" do
    test "kills existing Terminator" do
      {:ok, %{pid: pid}} = Terminators.create("iwilldie")
      assert pid in get_child_pids(TerminatorSupervisor)

      conn = make_request(:delete, "/terminators/iwilldie")

      assert conn.status == 204
      refute pid in get_child_pids(TerminatorSupervisor)
    end

    test "gracefully handles non existing Terminator" do
      conn = make_request(:delete, "/terminators/dunnothisone")

      assert conn.status == 404
      assert Jason.decode!(conn.resp_body) == %{"errors" => ["Not Found"]}
    end
  end

  describe "API Error handling" do
    test "renders 404 for unknown endpoints" do
      conn = make_request(:get, "/some/fakeurl")

      assert conn.status == 404
      assert Jason.decode!(conn.resp_body) == %{"errors" => ["Not Found"]}
    end
  end

  defp get_child_pids(supervisor) do
    supervisor
    |> DynamicSupervisor.which_children()
    |> Enum.map(fn {:undefined, pid, _, _} -> inspect(pid) end)
  end
end
