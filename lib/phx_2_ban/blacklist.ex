defmodule Phx2Ban.Blacklist do
  @moduledoc false

  use GenServer

  alias Phx2Ban.Telemetry
  alias Plug.Conn

  @ip_filter_key {__MODULE__, :ip_filter}
  @cuckoo_filter_capacity 2 ** 16

  # ---- Public API ----

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc false
  def block_ip_address(remote_ip) do
    GenServer.cast(__MODULE__, {:block_ip_address, remote_ip})
  end

  @doc false
  def valid_ip_address?(%Conn{remote_ip: nil}) do
    true
  end

  def valid_ip_address?(%Conn{remote_ip: remote_ip}) do
    # We check for false here as opposed to true since Cuckoo filters
    # guarantee that the element is "definitely not in set" but checking for
    # true would trip the "possibly in set" behaviour.

    blacklisted_ip_address =
      @ip_filter_key
      |> :persistent_term.get()
      |> :cuckoo_filter.contains(remote_ip)

    not blacklisted_ip_address
  end

  # ---- Server Callbacks ----

  @impl true
  def init(opts) do
    # This always needs to be set up in order to quickly get the rejected IP addresses
    :persistent_term.put(@ip_filter_key, :cuckoo_filter.new(@cuckoo_filter_capacity))
    blocked_ip_table = :ets.new(__MODULE__, [:duplicate_bag, :private])

    state = %{
      blocked_ip_table: blocked_ip_table,
      check_interval: Keyword.get(opts, :check_interval, 60_000),
      block_duration: Keyword.get(opts, :block_duration, 360_000)
    }

    {:ok, state, {:continue, :schedule_timer}}
  end

  @impl true
  def handle_continue(:schedule_timer, %{check_interval: check_interval} = state) do
    Process.send_after(self(), :clear_expired_blocks, check_interval)

    {:noreply, state}
  end

  @impl true
  def handle_cast(
        {:block_ip_address, remote_ip},
        %{blocked_ip_table: blocked_ip_table, block_duration: block_duration} = state
      ) do
    # Update the Cuckoo filter
    @ip_filter_key
    |> :persistent_term.get()
    |> :cuckoo_filter.add(remote_ip)

    # Add the IP to the ETS blocked IP table
    unblock_at_timestamp = System.monotonic_time() + System.convert_time_unit(block_duration, :millisecond, :native)

    :ets.insert(blocked_ip_table, {unblock_at_timestamp, remote_ip})
    Telemetry.execute_blacklist_ip_blocked(remote_ip)

    {:noreply, state}
  end

  @impl true
  def handle_info(:clear_expired_blocks, %{blocked_ip_table: blocked_ip_table} = state) do
    query = [
      {
        {:"$1", :"$2"},
        [{:<, :"$1", System.monotonic_time()}],
        [:"$_"]
      }
    ]

    blocked_ip_table
    |> :ets.select(query)
    |> Enum.each(fn {key, ip_address} ->
      # Removing the IP address from ETS
      :ets.delete(blocked_ip_table, key)

      # Remove the IP address from Cuckoo filter
      @ip_filter_key
      |> :persistent_term.get()
      |> :cuckoo_filter.delete(ip_address)

      Telemetry.execute_blacklist_ip_unblocked(ip_address)
    end)

    {:noreply, state, {:continue, :schedule_timer}}
  end
end
