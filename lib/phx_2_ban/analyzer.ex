defmodule Phx2Ban.Analyzer do
  @moduledoc """
  This function provides a default list of paths that should result
  in a banned IP address. While not as complete as https://github.com/fail2ban/fail2ban
  in terms of requests that are flagged as invalid, most site scanning tools
  look for Wordpress, Java and Microsoft servers and these default rules are enough to
  catch most offeneding requesters.
  """

  use GenServer

  alias Phx2Ban.Blacklist
  alias Phx2Ban.ConnData
  alias Phx2Ban.Filters
  alias Plug.Conn

  # ---- Public API ----

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc false
  def analyze_request(%Conn{} = conn) do
    data_to_analyze = ConnData.from_conn(conn)

    GenServer.cast(__MODULE__, {:analyze_request, data_to_analyze})
  end

  # ---- Server Callbacks ----

  @impl true
  def init(opts) do
    default_rules = [
      &Filters.common_extensions/1,
      &Filters.php_file_extensions/1,
      &Filters.linux_files/1
    ]

    state = %{
      rules: Keyword.get(opts, :rules, default_rules)
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:analyze_request, %ConnData{remote_ip: remote_ip} = data_to_analyze}, state) do
    if should_blacklist_ip?(data_to_analyze, state) do
      Blacklist.block_ip_address(remote_ip)
    end

    {:noreply, state}
  end

  # ---- Helpers ----

  defp should_blacklist_ip?(%ConnData{} = data_to_analyze, state) do
    state.rules
    |> Enum.any?(fn rule ->
      rule.(data_to_analyze)
    end)
  end
end
