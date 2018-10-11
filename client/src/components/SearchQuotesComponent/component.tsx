import React from "react";
import { Cancelable } from "lodash";
import debounce from "lodash-es/debounce";
import update from "immutability-helper";
import { ApolloQueryResult } from "apollo-client";
import { Input } from "semantic-ui-react";
import { List } from "semantic-ui-react";
import { Message } from "semantic-ui-react";
import { Icon } from "semantic-ui-react";
import { NavLink } from "react-router-dom";

import { AllMatchingTexts as AllMatchingTextsQuery } from "../../graphql/gen.types";
import { SearchQuotesState } from "./utils";
import { SearchQuotesProps } from "./utils";
import ALL_MATCHING_TEXT_QUERY from "../../graphql/text-search.query";
import { classes } from "./styles";
import ErrorBoundary from "../../containers/error-boundary.container";
import { SemanticOnInputChangeFunc } from "./utils";
import { TextSearchResultFrag } from "../../graphql/gen.types";
import { TextSearchRowFrag } from "../../graphql/gen.types";
import { makeSourceURL } from "../../routes/util";
import { makeTagURL } from "../../routes/util";

export class SearchQuotesComponent extends React.Component<
  SearchQuotesProps,
  SearchQuotesState
> {
  state: SearchQuotesState = {
    searchText: "",
    searchLoading: false
  };

  doSearchDebounced: (() => void) & Cancelable;

  constructor(props: SearchQuotesProps) {
    super(props);

    this.doSearchDebounced = debounce(this.doSearch, 700);
  }

  componentWillUnmount() {
    this.doSearchDebounced.cancel();
  }

  render() {
    return (
      <div className={classes.root}>
        <form>
          <Input
            className={classes.input}
            icon="search"
            placeholder="Search..."
            fluid={true}
            autoFocus={true}
            onChange={this.onSearchInputChange}
            value={this.state.searchText}
            loading={this.state.searchLoading}
          />
        </form>

        <ErrorBoundary className={classes.mainContent}>
          <div className={classes.mainContent}>
            {this.state.searchError && (
              <Message
                error={true}
                icon={true}
                style={{
                  marginTop: "20px"
                }}
              >
                <Icon name="ban" />

                <Message.Content>
                  <Message.Header
                    style={{
                      borderBottom: "1px solid",
                      display: "inline-block",
                      marginBottom: "10px"
                    }}
                  >
                    An error has occurred
                  </Message.Header>
                  <div>{JSON.stringify(this.state.searchError, null, 2)}</div>
                </Message.Content>
              </Message>
            )}

            {!this.state.searchError &&
              this.state.searchText &&
              this.state.result &&
              this.renderResult(this.state.result)}
          </div>
        </ErrorBoundary>
      </div>
    );
  }

  onSearchInputChange: SemanticOnInputChangeFunc = (e, { value }) => {
    // if user is pressing backspace or clearing texts in any other way, when
    // the text input is clear, we clear search results. This fixes the bug
    // where after user clears input and then begin typing again, we render the
    // stale search result before hitting network
    let { result } = this.state;
    result = value ? result : undefined;

    this.setState(s =>
      update(s, {
        searchText: {
          $set: value
        },

        searchError: {
          $set: undefined
        },

        result: {
          $set: result
        }
      })
    );

    this.doSearchDebounced();
  };

  doSearch = async () => {
    const searchText = this.state.searchText.trim();

    if (searchText.length < 2) {
      return;
    }

    this.setState(s =>
      update(s, {
        searchLoading: {
          $set: true
        }
      })
    );

    try {
      const result = (await this.props.client.query({
        query: ALL_MATCHING_TEXT_QUERY,
        variables: {
          text: {
            text: searchText
          }
        }
      })) as ApolloQueryResult<AllMatchingTextsQuery>;

      this.setState(s =>
        update(s, {
          searchLoading: {
            $set: false
          },

          result: {
            $set: result.data.quoteFullSearch
          }
        })
      );
    } catch (error) {
      this.setState(s =>
        update(s, {
          searchLoading: {
            $set: false
          },

          searchError: {
            $set: error
          }
        })
      );
    }
  };

  renderResult = ({
    quotes,
    tags,
    authors,
    sources,
    sourceTypes
  }: TextSearchResultFrag) => {
    return authors || quotes || sources || sourceTypes || tags ? (
      <div className={classes.resultContainer}>
        {[quotes, tags, authors, sources, sourceTypes].map(this.renderCategory)}
      </div>
    ) : (
      <Message
        className={classes.resultContainer}
        style={{ textAlign: "center", padding: "10px" }}
        icon={true}
        warning={true}
        size="small"
      >
        <Icon
          name="warning"
          size="tiny"
          fitted={true}
          style={{ fontSize: "2em" }}
        />
        <Message.Content>No Result!</Message.Content>
      </Message>
    );
  };

  renderCategory = (data: TextSearchRowFrag[]) => {
    if (!data) {
      return;
    }

    const header = data[0].source;
    const methodName = header[0] + header.slice(1, -1).toLowerCase();
    const render = this[`renderRow${methodName}`] || this.renderRow;

    return (
      <div className={classes.result} key={header}>
        <div className={classes.resultRowHeaderContainer}>
          <span className={classes.resultRowHeader}>{header}</span>
        </div>

        <List divided={true}>{data.map(render)}</List>
      </div>
    );
  };

  renderRow = ({ text, tid, column }: TextSearchRowFrag) => {
    return (
      <List.Item key={tid + column} className={classes.resultRowItem}>
        <List.Content>{text}</List.Content>
      </List.Item>
    );
  };

  renderRowSource = ({ text, tid, column }: TextSearchRowFrag) => {
    return (
      <List.Item
        key={tid + column}
        className={classes.resultRowItem}
        as={NavLink}
        to={makeSourceURL(tid.toString())}
      >
        <List.Content>{text}</List.Content>
      </List.Item>
    );
  };

  renderRowTag = ({ text, tid, column }: TextSearchRowFrag) => {
    return (
      <List.Item
        key={tid + column}
        className={classes.resultRowItem}
        as={NavLink}
        to={makeTagURL(tid.toString())}
      >
        <List.Content>{text}</List.Content>
      </List.Item>
    );
  };
}

export default SearchQuotesComponent;
