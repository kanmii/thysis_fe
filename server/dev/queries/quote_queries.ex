defmodule GasWeb.QuoteQueries do
  alias GasWeb.TagQueries
  alias GasWeb.SourceQueries
  alias GasWeb.AuthorQueries

  def all_fields_fragment do
    name = "QuoteAllFieldsFragment"

    fragment = """
    fragment #{name} on Quote {
      id
      text
      date
      pageStart
      pageEnd
      volume
      issue
      extras
      insertedAt
      updatedAt
    }
    """

    {name, fragment}
  end

  def mutation(:create_quote) do
    {frag_name, frag} = all_fields_fragment()
    {tag_frag_name, tag_frag} = TagQueries.all_fields_fragment()
    {source_frag_name, source_frag} = SourceQueries.all_fields_fragment()
    {author_frag_name, author_frag} = AuthorQueries.all_fields_fragment()

    """
      mutation createQuote($quote: CreateQuoteInput!) {
        createQuote(quote: $quote) {
          ...#{frag_name}

          source {
            ...#{source_frag_name}

            authors {
              ...#{author_frag_name}
            }
          }

          tags {
            ...#{tag_frag_name}
          }
        }
      }

      #{frag}
      #{tag_frag}
      #{source_frag}
      #{author_frag}
    """
  end

  def mutation() do
    {frag_name, frag} = all_fields_fragment()
    {source_frag_name, source_frag} = SourceQueries.all_fields_fragment()

    """
    mutation createQuote($quote: CreateQuoteInput!) {
      createQuote(quote: $quote) {
        ...#{frag_name}
        source {
          ...#{source_frag_name}
        }
      }
    }

    #{frag}
    #{source_frag}
    """
  end

  def query(:quotes) do
    {frag_name, frag} = all_fields_fragment()
    {source_frag_name, source_frag} = SourceQueries.all_fields_fragment()
    {author_frag_name, author_frag} = AuthorQueries.all_fields_fragment()

    """
    query GetQuotesQuery($quote: GetQuotes) {
      quotes(quote: $quote) {
        ...#{frag_name}

        source {
          ...#{source_frag_name}

          authors {
            ...#{author_frag_name}
          }
        }
      }
    }

    #{frag}
    #{source_frag}
    #{author_frag}
    """
  end

  def query(:full_text_search) do
    result_row = """
    {
      tid
      text
      source
      column
    }
    """

    """
    query GetAllMatchingTexts($text: QuoteFullSearchInput!) {
      quoteFullSearch(text: $text) {
        quotes      #{result_row}
        sources     #{result_row}
        tags        #{result_row}
        sourceTypes #{result_row}
        authors     #{result_row}
      }
    }
    """
  end

  def variables do
    %{
      "quote" => %{
        "date" => "1111-11-11",
        "extras" => "1111",
        "pageStart" => 1,
        "quote" => "aaaa",
        "sourceId" => "234",
        "tags" => ["151", "103", "104"],
        "text" => "",
        "volume" => "11"
      }
    }
  end
end
