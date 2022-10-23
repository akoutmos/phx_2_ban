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
  alias Plug.Conn

  # ---- Public API ----

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc false
  def analyze_request(%Conn{} = conn) do
    data_to_analyze = Map.take(conn, [:remote_ip, :method, :request_path, :status])

    GenServer.cast(__MODULE__, {:analyze_request, data_to_analyze})
  end

  @doc """
  This rule will flag common path extensions that belong to other (and commonly
  exploited) languages such as PHP, .NET, and Java as well as OS extensions like
  Windows.
  """
  def common_extensions(%{request_path: request_path}) do
    Regex.match?(~r/\.(?:php|jsp|cgi|cfm|exe|bat|dll|asp|aspx|ini)$/, request_path)
  end

  @doc """
  This rul will flag requests that aim to find PHP files.
  """
  def php_file_extensions(%{request_path: request_path}) do
    Regex.match?(~r/\.php.(?:tmp|bkp|old|orig|swp|temp|copy|backup|save)$/, request_path)
  end

  @doc """
  This rule will flag requests that aim to extract files from the OS.
  """
  def linux_files(%{request_path: request_path}) do
    Regex.match?(
      ~r/\.(?:htaccess|git|bashrc|zshrc|cvs|passwd|web|gitignore|svnignore|htpasswd)$/,
      request_path
    )
  end

  # ---- Server Callbacks ----

  @impl true
  def init(opts) do
    default_rules = [
      &__MODULE__.common_extensions/1,
      &__MODULE__.php_file_extensions/1,
      &__MODULE__.linux_files/1
    ]

    state = %{
      rules: Keyword.get(opts, :rules, default_rules)
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:analyze_request, %{remote_ip: remote_ip} = data_to_analyze}, state) do
    if should_blacklist_ip?(data_to_analyze, state) do
      Blacklist.block_ip_address(remote_ip)
    end

    {:noreply, state}
  end

  # ---- Helpers ----

  defp should_blacklist_ip?(data_to_analyze, state) do
    state.rules
    |> Enum.any?(fn rule ->
      rule.(data_to_analyze)
    end)
  end
end
