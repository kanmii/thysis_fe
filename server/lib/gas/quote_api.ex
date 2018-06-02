defmodule Gas.QuoteApi do
  @moduledoc """
  The Quotes context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Gas.Repo
  alias Gas.Quote
  alias Gas.QuoteTag

  @doc """
  Returns the list of quotes.

  ## Examples

      iex> list()
      [%Quote{}, ...]

  """
  def list do
    Repo.all(Quote)
  end

  @doc """
  Gets a single quote.

  Raises `Ecto.NoResultsError` if the Quote does not exist.

  ## Examples

      iex> get!(123)
      %Quote{}

      iex> get!(456)
      ** (Ecto.NoResultsError)

  """
  def get!(id), do: Repo.get!(Quote, id)

  @doc """
  Creates a quote.

  ## Examples

      iex> create_(%{field: value})
      {:ok, %Quote{}}

      iex> create_(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_(attrs \\ %{}) do
    %Quote{}
    |> Quote.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a quote with one or more tags in a single transaction

  ## Examples

      iex> create_with_tags(%{
                tags: ["1", 2, "3"],
                text: "cool quote",
                source_id: "1"
            })
      {:ok, %{quote: %Quote{}, quote_tags: 3}}

      iex> create_with_tags(%{
                tags: ["1", 2, "3"],
                text: "cool quote",
                source_id: "1"
            })
      {:error, field_operations_names, changeset, successful_operations}
  """

  @spec create_with_tags(%{
          tags: [String.t() | Integer.t()],
          text: String.t(),
          source_id: String.t() | Integer.t()
        }) ::
          {:ok, %{quote: %Quote{}, quote_tags: Integer.t()}}
          | {:error, Multi.name(), any(), %{optional(Multi.name()) => any()}}
  def create_with_tags(%{tags: tags} = inputs) do
    Multi.new()
    |> Multi.insert(
      :quote,
      change_(%Quote{}, Map.delete(inputs, :tags))
    )
    |> Multi.merge(fn %{quote: %Quote{id: id}} ->
      now = Timex.now()

      quote_tags =
        Enum.map(
          tags,
          &[
            tag_id: String.to_integer("#{&1}"),
            quote_id: id,
            inserted_at: now,
            updated_at: now
          ]
        )

      Multi.new()
      |> Multi.insert_all(:quote_tags, QuoteTag, quote_tags)
    end)
    |> Repo.transaction()
  end

  @doc """
  Updates a quote.

  ## Examples

      iex> update_(quote, %{field: new_value})
      {:ok, %Quote{}}

      iex> update_(quote, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_(%Quote{} = quote, attrs) do
    quote
    |> Quote.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Quote.

  ## Examples

      iex> delete_(quote)
      {:ok, %Quote{}}

      iex> delete_(quote)
      {:error, %Ecto.Changeset{}}

  """
  def delete_(%Quote{} = quote) do
    Repo.delete(quote)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking quote changes.

  ## Examples

      iex> change_(quote)
      %Ecto.Changeset{source: %Quote{}}

  """
  def change_(%Quote{} = quote, attrs \\ %{}) do
    Quote.changeset(quote, attrs)
  end
end