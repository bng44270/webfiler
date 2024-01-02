from subprocess import check_output as run_shell
from re import sub as regex_sub

def nl2br(str):
  return regex_sub(r"\n","<br/>",str)

def ShellRun(filespec,args=[]):
    try:
      cmdar = [filespec]
      cmdar.extend(args)
      process = run_shell(cmdar)
      outputstr = process.decode('ascii')
      return nl2br(outputstr)
    except:
      return "Error running shell script"
