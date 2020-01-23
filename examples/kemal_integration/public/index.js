var app = new Vue({
  el: '#app',
  data: {
    loaded: false,
    logged_in: false,
    username: null
  },
  beforeMount: function () {
    this.$nextTick(function () {
      var urlParams = new URLSearchParams(window.location.search);
      token = urlParams.get("token")
      if(token == null) {
        this.logged_in = false
        this.loaded = true
      } else {
        fetch('/verify', {headers: {token}})
          .then(response => response.json())
          .then(data => {
            this.logged_in = true
            this.username = data.name
            this.loaded = true
          })
          .catch((err) => {
            console.log('Fetch Error :-S', err);
            this.loaded = true
          });
      }
    })
  },
  methods: {
    logout: function(e) {
      console.log("logging out")
      var urlParams = new URLSearchParams(window.location.search);
      token = urlParams.get("token")
      fetch('/logout', {headers: {token}})
        .then(response => {
          this.logged_in = false
          this.username = null
        }
      )
      .catch(err => {
        console.log('Fetch Error :-S', err);
        this.loaded = true
      });
    }
  }
})
