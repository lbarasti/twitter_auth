var app = new Vue({
  el: '#app',
  beforeMount: function () {
    this.$nextTick(function () {
      var urlParams = new URLSearchParams(window.location.search);
      token = urlParams.get("token")
      if(token == null) {
        this.logged_in = false
        this.loaded = true
      } else {
        fetch('/verify', {headers: {token}})
          .then(response => {
              if (response.status !== 200) {
                console.log('Looks like there was a problem. Status Code: ' +
                  response.status);
                this.loaded = true
                return;
              }

              response.json().then((data) => {
                console.log(typeof(data))
                this.logged_in = true
                this.username = data.name
                this.loaded = true
              });
            }
          )
          .catch(function(err) {
            console.log('Fetch Error :-S', err);
            this.loaded = true
          });
      }
    })
  },
  data: {
    loaded: false,
    logged_in: false,
    username: null
  },
  computed: {
    
  },
  methods: {
    logout: function(e) {
      console.log("logging out")
      var urlParams = new URLSearchParams(window.location.search);
      token = urlParams.get("token")
      fetch('/logout', {headers: {token}})
        .then(response => {
          if (response.status !== 200) {
            console.log('Looks like there was a problem. Status Code: ' +
              response.status);
          }
          this.logged_in = false
          this.username = null
        }
      )
      .catch(function(err) {
        console.log('Fetch Error :-S', err);
        this.loaded = true
      });
    }
  }
})
