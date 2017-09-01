// ------------------------------------------------------
// Import all required packages and files
// ------------------------------------------------------

let Pusher     = require('pusher');
let express    = require('express');
let app        = express();
let bodyParser = require('body-parser')
let pusher     = new Pusher(require('./config.js'));

// ------------------------------------------------------
// Set up Express
// ------------------------------------------------------

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));

// ------------------------------------------------------
// Define routes and logic
// ------------------------------------------------------

app.post('/status', (req, res, next) => {
  let payload = {username: req.body.username, status: req.body.status};
  pusher.trigger('new_status', 'update', payload);
  res.json({success: 200});
});

app.post('/online', (req, res, next) => {
  let payload = {username: req.body.username};
  pusher.trigger('new_status', 'online', payload);
  res.json({success: 200});
});

app.get('/', (req, res) => {
  res.json("It works!");
});


// ------------------------------------------------------
// Catch errors
// ------------------------------------------------------

app.use((req, res, next) => {
    let err = new Error('Not Found: ');
    console.log(req)
    err.status = 404;
    next(err);
});


// ------------------------------------------------------
// Start application
// ------------------------------------------------------

app.listen(4000, () => console.log('App listening on port 4000!'));