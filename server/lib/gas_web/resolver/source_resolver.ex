defmodule GasWeb.SourceResolver do
  @moduledoc """
  A resolver for the source schema
  """
  alias Gas.Source
  alias Gas.SourceApi, as: Api
  alias GasWeb.ResolversUtil

  @doc """
  Get all sources.
  """
  @spec sources(any, any, any) :: {:ok, [%Source{}]}
  def sources(_root, _args, _info) do
    {:ok, Api.list(:authors)}
  end

  @doc """
  Get one source.
  """
  @spec source(any, %{source: %{id: String.t()}}, any) :: {:ok, %Source{}} | {:error, String.t()}
  def source(_root, %{source: %{id: id}} = _args, _info) do
    case Api.get(id) do
      %Source{} = source_ -> {:ok, source_}
      nil -> {:error, "No source with id: #{id}"}
    end
  end

  @doc """
  Returns a string that can be used to display the source (sort of to_string).
  The fields that are important are joined together with "|". Fields that are
  `nil` are ignored
  """
  @spec display(%Source{}, any, any) :: {:ok, String.t()} | {:error, String.t()}
  def display(%Source{} = source, _, _) do
    text =
      source
      |> Map.take([:authors, :topic, :publication, :year, :url])
      |> map_reduce()
      |> Enum.join(" | ")

    {:ok, text}
  end

  defp map_reduce(list) when is_list(list), do: Enum.map(list, &map_reduce/1)

  defp map_reduce(%{} = map) do
    Enum.reduce(map, [], fn
      {:authors, authors}, acc ->
        authors =
          authors
          # |> Map.from_struct()
          |> Enum.map(&Map.take(&1, [:name]))

        Enum.concat(acc, map_reduce(authors))

      {_, nil}, acc ->
        acc

      {_, val}, acc when is_list(val) or is_map(val) ->
        Enum.concat(acc, map_reduce(val))

      {_, v}, acc ->
        [v | acc]
    end)
    |> Enum.reverse()
  end

  defp map_reduce(val), do: val

  @doc """
  Create a source
  """
  @spec create(any, %{source: Map.t()}, any) :: {:ok, %Source{}} | {:error, String.t()}
  def create(_root, %{source: inputs} = _args, _info) do
    case Api.create_(inputs) do
      {:ok, %{source: source}} ->
        {:ok, source}

      {:error, failed_operation, changeset, _success} ->
        {
          :error,
          ResolversUtil.transaction_errors_to_string(
            changeset,
            failed_operation
          )
        }
    end
  end

  @doc """
  Create a source
  """
  @spec update(any, %{source: %{id: Integer.t() | String.t()}}, any) ::
          {:ok, %Source{}} | {:error, String.t()}
  def update(_root, %{source: %{id: id} = inputs} = _args, _info) do
    case Api.get(id) do
      nil ->
        {:error, "No source with id: #{id}"}

      source ->
        case Api.update_(source, inputs) do
          {:ok, %{source: source}} ->
            {:ok, source}

          {:error, failed_operation, changeset, _success} ->
            {
              :error,
              ResolversUtil.transaction_errors_to_string(
                changeset,
                failed_operation
              )
            }
        end
    end
  end
end
