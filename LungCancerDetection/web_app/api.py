from flask import Flask


#HTML code
STATUS_OK = 200
NOT_FOUND = 404
BAD_REQUEST = 400
BAD_PARAM = 450

#app
app = Flask(__name__)

#define static folder for css,img,js
app.static_folder = 'static'