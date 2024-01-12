from subprocess import Popen as open_proccess, PIPE, STDOUT
from re import sub as regex_sub
from renderers import BaseRenderer

class PythonRenderer(BaseRenderer):
  def __init__(self,filespec,args=[],pipein=None):
    super().__init__(filespec,args,pipein)
  
  def get_puthon_bin(self):
    try:
      proc = open_proccess(["which","python3"],stdout=PIPE)
      cmdout = ''.join([a.decode('ascii') for a in proc.stdout.readlines()])
      return cmdout.strip()
    except:
      return False
  
  def run(self):
    self.activetemplate = "bare"
    
    try:
      pybin = self.get_python_bin()
      cmdar = [pybin,self.file]
      cmdar.extend(self.args)
      process = open_proccess(cmdar,stdout=PIPE, stdin=PIPE, stderr=PIPE)
      outputstr = None
      if self.pipe_data:
        outputstr = process.communicate(input=bytes(self.pipe_data,'utf-8'))[0].decode('ascii')
      else:
        outputstr = ''.join([a.decode('ascii') for a in process.stdout.readlines()])
      return {"tmpl":self.activetemplate,"content":self.nl2br(outputstr)}
    except:
      return "Error running Python script"