const express = require("express");
const mongoose = require("mongoose");
const bodyParser = require("body-parser");
const passport = require("passport");
const settings = require("./config/keys");

const user = require("./routes/api/user");
const profile = require("./routes/api/profile");
const post = require("./routes/api/post");

// Logging Configuration
var morgan = require('morgan');
var uuid = require('node-uuid');
morgan.token('id', function getId (req) {
  return req.id
})

const app = express();

app.use(assignId);
app.use(
  morgan(':id :remote-addr :remote-user :method :url [:status] :response-time',{
    skip: function (req, res) { return req.url === "/test" }
  })
);

function assignId (req, res, next) {
  req.id = uuid.v4()
  next()
}

// Body Parser Middleware
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

// Database Configuration and Connection
const db = require("./config/keys").mongoURI.trim();
mongoose
  .connect(db)
  .then(() => console.log("Mongo DB Connected."))
  .catch(err => console.log(err));

// Passport Middleware
app.use(passport.initialize());
require("./config/passport")(passport);

app.use(settings.URL_BASE+"/user", user);
app.use(settings.URL_BASE+"/profile", profile);
app.use(settings.URL_BASE+"/post", post);

const port = process.env.PORT || 8080;

app.listen(port, () => console.log(`Server running on port ${port}`));
