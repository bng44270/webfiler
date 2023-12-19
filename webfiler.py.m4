from flask import Flask, render_template, send_file, request, redirect
from flask_wtf.csrf import CSRFProtect
from werkzeug.utils import secure_filename
import os
import re
import time
from base64 import b64decode as base64_decode
from json import loads as str2dict

webroot = "LOCALPATH"

webassets = os.listdir('assets')


csrf = CSRFProtect()

app = Flask(__name__)
app.config['SECRET_KEY'] = os.urandom(32)
csrf.init_app(app)

def username_to_uid(username):
  with open('/etc/passwd','r') as f:
    try:
      uid = [a.split(":")[2] for a in f.readlines() if a.split(":")[0] == str(username)][0]
      return uid
    except:
      return False

def uid_to_username(uid):
  with open('/etc/passwd','r') as f:
    try:
      username = [a.split(":")[0] for a in f.readlines() if a.split(":")[2] == str(uid)][0]
      return username
    except:
      return ""

@app.route("/", defaults ={'path':''}, methods=["GET","POST"])
@app.route("/<path:path>", methods=["GET","POST"])
def GetLogs(path):
  thispath = webroot + "/" + path
  if request.method == "GET":
    if path in webassets:
      return send_file("assets/" + path)
    elif os.path.isfile(thispath) and request.method == "GET":
      fileinfo = {}
      fileinfo["shortname"] = re.sub(webroot,"",thispath)
      with open(thispath,"r") as f:
        filecontent = f.readlines()
      
      fileinfo["content"] = ("\n".join(filecontent)).replace("\n\n","\n")
      
      return render_template('filedisplay.html',fileinfo = fileinfo)
    else:
      dirlist = {}
      dirlist["path"] = re.sub("\/\/","/","/" + path + "/")
      dirlist["isroot"] = thispath != (webroot + "/")
      dirlist["files"] = []
      for thisfile in os.listdir(thispath):
        owner = uid_to_username(os.stat(thispath + "/" + thisfile).st_uid)
        shortfile = re.sub(webroot,"",thisfile)
        if os.path.isfile(thispath + "/" + thisfile):
          ftype="F"
        elif os.path.isdir(thispath + "/" + thisfile):
          ftype="D"
        else:
          ftype="X"
        
        if len(path) == 0:
          linkpath = re.sub("\/\/","/",path + "/" + shortfile)
        else:
          linkpath = re.sub("\/\/","/","/" + path + "/" + shortfile)
        
        dirlist["files"].append({"shortname":shortfile,"path":linkpath,"type":ftype,"modify":time.ctime(os.path.getmtime(thispath + "/" + thisfile)),"size":os.path.getsize(thispath + "/" + thisfile),"owner":owner})
        
      return render_template('filelist.html', dirlist = dirlist)
  elif request.method == "POST":
    if re.match(r"^\$\/uservalidate",path):
      try:
        username = request.form["username"]

        if username_to_uid(username):
          return "{\"success\":true}"
        else:
          return "{\"success\":false,\"msg\":\"Invalid Username\"}"
      except Exception as e:
        return "{\"success\":false,\"msg\":\"" + str(e) + "ssss\"}"
    elif re.match(r"^\$\/savefile",path):
      try:
        filename = request.form["filespec"]
        content = str2dict(request.form["content"])
        username = request.form["username"]
        fullfilepath = os.path.join(webroot + filename)

        owner = uid_to_username(os.stat(fullfilepath).st_uid)
        if owner == username:
          os.remove(fullfilepath)
          with open(fullfilepath,'w') as f:
            f.write((''.join([chr(a) for a in content])).replace('\n\n','\n'))
          return "{\"success\":true}"
        else:
          return "{\"success\":false,\"msg\":\"Invalid permissions to modify file\"}"
      except Exception as e:
        return "{\"success\":false,\"msg\":\"" + str(e) + "\"}"
    elif re.match(r"^\$\/upload",path):
      try:
        file = request.files["uploadfile"]
        folder = request.form["folder"]
        username = request.form["username"]
        filename = secure_filename(file.filename)
        fullfilepath = os.path.join(webroot + str(folder),filename)

        if os.path.exists(fullfilepath):
          owner = uid_to_username(os.stat(fullfilepath).st_uid)
          if owner == username:
            os.remove(fullfilepath)
            file.save(fullfilepath)
            return "{\"success\":true}"
          else:
            return "{\"success\":false,\"msg\":\"Invalid permissions to modify file\"}"
        else:
          folderpath = os.path.join(webroot + str(folder))
          gid = os.stat(folderpath).st_gid
          file.save(fullfilepath)
          os.chown(fullfilepath,int(username_to_uid(username)),gid)
          return "{\"success\":true}"
      except Exception as e:
        return "{\"success\":false,\"msg\":\"" + str(e) + "\"}"
 


app.run("0.0.0.0",WEBPORT)
