from subprocess import check_output as run_shell
from re import sub as regex_sub

def get_python_bin():
  proc = run_shell(["which","python3"])
  if proc:
    return (proc.decode("ascii")).strip()
  else:
    return False

def nl2br(str):
  return regex_sub(r"\n","<br/>",str)

def PythonRun(filespec,args=[]):
    try:
      pybin = get_python_bin()
      cmdar = [pybin,filespec]
      cmdar.extend(args)
      process = run_shell(cmdar)
      outputstr = process.decode('ascii')
      return nl2br(outputstr)
    except:
      return "Error running Python script"
