from flask import Flask, render_template, send_file, request, make_response
from flask_wtf.csrf import CSRFProtect
from werkzeug.utils import secure_filename
import os
import re
import time
from json import loads as json_parse
import pam

webroot = "LOCALPATH"

webassets = os.listdir('assets')

available_extensions = [re.sub(r"^r_([^\.]+)\.html","\\1",a) for a in os.listdir('templates') if a.startswith('r_')]

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

def parsebool(v):
  if re.match(r"true",v,flags=re.I):
    return True
  elif re.match(r"false",v,flags=re.I):
    return False
  else:
    return None

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

      fileoperation = request.cookies.get("webfiler_operation")
      
      if not fileoperation:
        resp = make_response(fileinfo["content"])
        resp.set_cookie("webfiler_operation","readonly")
        return resp
      elif fileoperation == "readonly":
        filetype = re.sub(r"^.*\.([^\.]+)$","\\1",fileinfo["shortname"])
        if filetype in available_extensions:
          return render_template(f"r_{filetype}.html",fileinfo = fileinfo)
        else:
          return render_template("renderdefault.html",fileinfo = fileinfo)
      elif fileoperation == "readwrite":
        return render_template('filedisplay.html',fileinfo = fileinfo)
      else:
        return render_template("operror.html",fileinfo = fileinfo)
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


      fileoperation = request.cookies.get("webfiler_operation")
      
      if not fileoperation or fileoperation == "readonly":
        dirlist["readonly"] = True
      else:
        dirlist["readonly"] = False

      resp = make_response(render_template('filelist.html', dirlist = dirlist))
      
      if not fileoperation:
        resp.set_cookie("webfiler_operation","readonly")
      else:
        resp.set_cookie("webfiler_operation",fileoperation)
      
      return resp
  elif request.method == "POST":
    if re.match(r"^\$\/authenticate",path):
      username = request.form["username"]
      password = request.form["password"]

      if pam.authenticate(username,password):
        return "{\"success\":true}"
      else:
        return "{\"success\":false,\"msg\":\"Authentication failed\"}"
    elif re.match(r"^\$\/uservalidate",path):
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
        content = json_parse(request.form["content"])
        username = request.form["username"]
        folder = request.form["folder"]
        fullfilepath = os.path.join(webroot + filename)

        owner = uid_to_username(os.stat(fullfilepath).st_uid)
        if owner == username:
          os.remove(fullfilepath)
          with open(fullfilepath,'w') as f:
            f.write((''.join([chr(a) for a in content])).replace('\n\n','\n'))
          
          folderpath = os.path.join(webroot + str(folder))
          gid = os.stat(folderpath).st_gid
          os.chown(fullfilepath,int(username_to_uid(username)),gid)
          return "{\"success\":true}"
        else:
          return "{\"success\":false,\"msg\":\"Invalid permissions to modify file\"}"
      except Exception as e:
        return "{\"success\":false,\"msg\":\"" + str(e) + "\"}"
    elif re.match(r"\$\/createfile",path):
      try:
        filename = request.form["filename"]
        folder = request.form["folder"]
        username = request.form["username"]
        fullfilepath = os.path.join(webroot + str(folder),filename)

        if os.path.exists(fullfilepath):
          return "{\"success\":false,\"msg\":\"File already exists\"}"
        else:
          with open(fullfilepath,"w") as f:
            f.write("")
          
          folderpath = os.path.join(webroot + str(folder))
          gid = os.stat(folderpath).st_gid
          os.chown(fullfilepath,int(username_to_uid(username)),gid)
          return "{\"success\":true}"
      except Exception as e:
        return "{\"success\":false,\"msg\":\"" + str(e) + "\"}"
    elif re.match(r"\$\/createfolder",path):
      try:
        foldername = request.form["foldername"]
        folder = request.form["folder"]
        username = request.form["username"]
        fullfolderpath = os.path.join(webroot + str(folder),foldername)

        if os.path.exists(fullfolderpath):
          return "{\"success\":false,\"msg\":\"Folder already exists\"}"
        else:
          os.mkdir(fullfolderpath)
          
          folderpath = os.path.join(webroot + str(folder))
          gid = os.stat(folderpath).st_gid
          os.chown(fullfolderpath,int(username_to_uid(username)),gid)
          return "{\"success\":true}"
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
 


app.run("0.0.0.0",WEBPORT,ssl_context=("CERTFILE","KEYFILE"))
