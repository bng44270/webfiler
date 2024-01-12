from re import sub as regex_sub
import os
from abc import ABC, abstractmethod

class BaseRenderer(ABC):
  def __init__(self,filespec="",args=[],pipein=None):
    self.file = filespec
    self.args = args
    self.pipe_data = pipein
    self._tmpl = []
    self._tmpl.append({"active":True,"name":"bare","file":"renderbare.html"})
    self._tmpl.append({"active":False,"name":"html","file":"renderpage.html"})
  
  def nl2br(self,str):
    return regex_sub(r"\n","<br/>",str)
  
  @property
  def activetemplate(self):
    return [a["file"] for a in self._tmpl if a["active"]][0]
  
  @activetemplate.setter
  def activetemplate(self,name):
    if name in [a["name"] for a in self._tmpl]:
      for t in self._tmpl:
        t["active"] = False
      
      for t in self._tmpl:
        if t["name"] == name:
          t["active"] = True
  
  def render(self):
    if os.path.exists(self.file):
      return self.run()
    else:
      return False
  
  @abstractmethod
  def run(self):
    pass
  
