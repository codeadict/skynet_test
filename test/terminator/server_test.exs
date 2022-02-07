defmodule Skynet.Terminator.ServerTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Skynet.Terminator.Server

  test "can reproduce after certain period" do
    reproduction_period_ms = 10

    pid =
      start_supervised!(
        {Server,
         [
           name: "origin_terminator",
           reproduction_odds: -1,
           reproduction_period: reproduction_period_ms
         ]}
      )

    :erlang.trace(pid, true, [:receive])

    # Wait a bit over the reproduction period
    Process.sleep(reproduction_period_ms + 1)

    assert_receive {:trace, ^pid, :receive, :maybe_reproduce}
  end

  test "can be eliminated after certain period" do
    elimination_period_ms = 10

    pid =
      start_supervised!(
        {Server,
         [
           name: "dead_terminator",
           elimination_odds: -1,
           elimination_period: elimination_period_ms
         ]}
      )
    ref = Process.monitor(pid)
    :erlang.trace(pid, true, [:receive])

    assert_receive {:trace, ^pid, :receive, :encounter_with_sarah}
    assert_receive {:DOWN, ^ref, :process, _object, :normal}
    refute Process.alive?(pid)
  end
end
