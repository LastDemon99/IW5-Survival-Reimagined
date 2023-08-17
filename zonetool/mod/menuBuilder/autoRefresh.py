import hashlib
import time
import sys
import subprocess

if __name__ == "__main__":
    print('=== Auto Refresh menu file ===')

    menuName = sys.argv[1]
    pyMenu = menuName + '.py'
    lastchecksum = ''

    while (True):
        with open(pyMenu, "rb") as f:
            checksum = hashlib.md5(f.read()).hexdigest()

            if checksum != lastchecksum:
                lastchecksum = checksum
                result = subprocess.run(['python', pyMenu], capture_output=True, text=True)          

                file = open(menuName + '.menu', 'w')
                file.write(result.stdout)
                file.close()

        time.sleep(0.5)