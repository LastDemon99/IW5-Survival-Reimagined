from os.path import exists
from os import chdir, getenv, remove
from subprocess import Popen
from shutil import move

def build(codPath, exeName, modFolderName):
    chdir(codPath)
    p = Popen([exeName, '-buildzone', 'mod'])
    p.wait()
    
    modPath = f'{codPath}/zone/english/mod.ff'
    iw5ModsFolder = f'{getenv("LOCALAPPDATA")}/Plutonium/storage/iw5/mods'
    savePath = f'{iw5ModsFolder}/{modFolderName}'

    if exists(iw5ModsFolder) and exists(modPath) and exists(savePath):
        remove(savePath + '/mod.ff')
        move(modPath, savePath + '/')
    elif not exists(modPath):
        print('ZoneTool could not create a build of the mod, please check the files for errors.')

if __name__ == '__main__':
    codPath = 'D:/Program Files/Steam/steamapps/common/Call of Duty Modern Warfare 3'
    build(codPath, 'zonetool.exe', 'lb_server')