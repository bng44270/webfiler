from re import sub as regex_sub
from json import loads
from renderers import BaseRenderer

class HtmlRenderer(BaseRenderer):
  def __init__(self,filespec):
    super().__init__(filespec)
  
  def run(self,tmpl="bare"):
    self.activetemplate = tmpl

    file_lines = []
    
    with open(self.file) as f:
      file_lines = f.readlines()
    
    pagecontent = ''.join(file_lines)    

    return {"tmpl":self.activetemplate,"content":pagecontent}

class PageRenderer(HtmlRenderer):
  def __init__(self,filespec):
    super().__init__(filespec)
  
  def run(self):
    return super().run(tmpl="html")
