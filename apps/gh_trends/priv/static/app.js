var { div
     , h1
     , h3
     , p
     , span
     , a
     , pre
     , button
     , input
     , label
     , form
     , submit
    } = React.DOM;

class Sync extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      startResult: "nothing yet",
      stopResult: "nothing yet",
      force: false,
      syncMs: ""
    }
    this.toggleForce = this.toggleForce.bind(this);
    this.setSyncMs = this.setSyncMs.bind(this);
    this.runStartSync = this.runStartSync.bind(this);
    this.runStopSync = this.runStopSync.bind(this);
  }

  toggleForce (e) {
    this.setState((prev, props) => {
      return {force: !prev.force}
    })
  }

  setSyncMs (e) {
    let v = e.target.value
    this.setState((prev, props) => {
      return {syncMs: v}
    })
  }

  runStartSync (e) {
    $.post(`/start_sync/${this.state.syncMs}?force=${this.state.force}`)
      .done((v) => {
        this.setState({startResult: v})
      })
      .fail((v) => {
        this.setState({startResult: `Failed: ${v.status}, ${v.responseText}`})
      })
  }

  runStopSync (e) {
    $.post("/stop_sync")
      .done((v) => {
        this.setState({stopResult: v})
      })
      .fail((v) => {
        this.setState({stopResult: `Failed: ${v.status}, ${v.responseText}`})
      })
  }

  render() {
    return div({className: "row"},
      div({className: "col-md-6 sync-start"},
          div({className: "form-inline"},
              div({className: "form-group"},
                 label({className: "sr-only", htmlFor: "sync-ms"}),
                 input({className: "form-control",
                        id: "sync-ms",
                        placeholder: "Sync in ms",
                        value: this.state.syncMs,
                        onChange: this.setSyncMs
                       })
                 ),
              div({className: "checkbox"},
                 label(null, input({type: "checkbox",
                                    checked: this.state.force,
                                    onClick: this.toggleForce
                                   })),
                 "Force"),
              button({type: "submit",
                      className: "btn btn-default",
                      onClick: this.runStartSync
                     },
                     "Start sync")
              ),
          div({id: "start-result"}, this.state.startResult)
         ),
       div({className: "col-md-6 sync-stop"},
         button({className: "btn btn-default",
                 onClick: this.runStopSync
                },
                "Stop sync"),
         div({id: "stop-result"}, this.state.stopResult)))
  }
}

class Repos extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      repos: []
    }

    this.reload = this.reload.bind(this);
  }

  componentDidMount() {
    return this.updateRepos
  }

  fetchRepos() {
    return $.getJSON("/repos")
      .done((rs) => {
        window.rs = rs
        return rs.sort((a, b) => b.stars - a.stars)
      })
  }

  updateRepos() {
    this.fetchRepos()
      .done((repos) => this.setState({repos: repos}))
      .fail((e) => console.error(e))
  }

  reload(e) {
    e.preventDefault()
    this.updateRepos()
  }

  render() {
    return (
      div({className: "repos list-group"},
          h3(null,
             "Repositories",
             span({className: "small"},
                  a({onClick: this.reload}, "[reload]"))),
        this.state.repos.map((v) => {
          return div({className: "list-group-item", key: v.id},
                     React.createElement(Repo, {repo: v}))
        })))
  }
}

class Repo extends React.Component {
  constructor(props) {
    super(props)
    this.state = {show: false, details: null, loaded: false}

    this.loadDetails = this.loadDetails.bind(this);
    this.toggleDetails = this.toggleDetails.bind(this);
    this.showDetails = this.showDetails.bind(this);
    this.hideDetails = this.hideDetails.bind(this);
  }

  loadDetails() {
    $.getJSON(`/repo/${this.props.repo.id}?verbose=true`)
      .done((v) => this.setState({details: v, loaded: true}))
      .error((e) => {
        console.error(e)
        return this.setState({details: v})
      })
  }

  toggleDetails(e) {
    e.preventDefault()
    this.state.show ? this.hideDetails() : this.showDetails()
  }

  showDetails() {
    if (this.state.loaded) {
      this.setState({show: true})
    } else {
      this.setState({show: true, details: ["loading"]})
      this.loadDetails()
    }

  }

  hideDetails() {
    this.setState({show: false})
  }

  render() {
    let r = this.props.repo
    return (
      div({className: "row"},
        div({className: "col-md-1"}, r.id),
        div({className: "col-md-1"},
            span({className: "glyphicon glyphicon-star small"}),
            r.stars),
        div({className: "col-md-4"},
            a({onClick: this.toggleDetails}, "[expand]"),
            r.name),
        div({className: "col-md-6"}, a({href: r.url}, r.url)),
      pre({className: this.state.show ? "show" : "hidden"},
        JSON.stringify(this.state.details, null, 2))
      )
    )
  }
}

ReactDOM.render(
  div(null,
      React.createElement(Sync),
      React.createElement(Repos)
     ),
  document.getElementById('main')
);
