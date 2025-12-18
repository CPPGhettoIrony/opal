#!/usr/bin/env python3

import sys
import os
import shutil
import json 

from os import path
from pathlib import Path

BASHRC = Path.home() / ".bashrc"

MARKER_START = "# >>> SDF-SDK ENV VARS >>>"
MARKER_END   = "# <<< SDF-SDK ENV VARS <<<"

SDK_DIR = Path(__file__).resolve().parent

ENV_VARS = {
    "SDF_SDK": str(SDK_DIR),
}

PATHS_TO_ADD = [
    str(SDK_DIR),
]


def update_bashrc():
    BASHRC.touch(exist_ok=True)
    content = BASHRC.read_text()

    # Remove old block if present
    if MARKER_START in content and MARKER_END in content:
        before = content.split(MARKER_START)[0]
        after = content.split(MARKER_END)[1]
        content = before + after

    block = [MARKER_START]

    # Export env vars
    for k, v in ENV_VARS.items():
        block.append(f'export {k}="{v}"')

    # PATH handling
    for p in PATHS_TO_ADD:
        block.extend([
            'case ":$PATH:" in',
            f'  *":{p}:"*) ;;',
            f'  *) PATH="$PATH:{p}" ;;',
            'esac',
        ])

    block.append("export PATH")
    block.append(MARKER_END)

    content = content.rstrip() + "\n\n" + "\n".join(block) + "\n"
    BASHRC.write_text(content)

    print("SDF SDK installed into ~/.bashrc")
    print("Run: source ~/.bashrc")

def uninstall():
    if not BASHRC.exists():
        print("Nothing to uninstall (.bashrc not found)")
        return

    content = BASHRC.read_text()

    if MARKER_START not in content or MARKER_END not in content:
        print("Opal SDK is not installed")
        return

    before = content.split(MARKER_START)[0]
    after = content.split(MARKER_END)[1]

    new_content = (before + after).rstrip() + "\n"
    BASHRC.write_text(new_content)

    print("Opal SDK uninstalled from ~/.bashrc")
    print("Run: source ~/.bashrc")

def check_install():
    if not BASHRC.exists():
        return False

    text = BASHRC.read_text()
    return MARKER_START in text and MARKER_END in text

REQUIRED_FILES = [
    "main.cu",
    "args.cuh",
    "scene.cuh",
    "materials.cuh",
    "makefile",
]

def init():

    cwd = os.getcwd() + '/'
    pth = os.environ["SDF_SDK"] + '/base/'

    #print(f"Copying files from {pth} to {cwd}...")

    for f in REQUIRED_FILES:
        if not path.exists(cwd + f):
            shutil.copy(pth + f, cwd + f)
            #print(f'Copied {pth + f}, {cwd + f}')

    if not path.exists(cwd + '.vscode'):

        shutil.copytree(pth + '.vscode', cwd + '.vscode')

        with open(cwd + '.vscode/c_cpp_properties.json', 'r+') as f:
            properties = json.loads(f.read())
            for conf in properties['configurations']:
                conf['includePath'].extend([pth, '/usr/include'])
            f.seek(0)
            f.write(json.dumps(properties))
            f.truncate()
        
def pull(f):

    cwd = os.getcwd() + '/'
    pth = os.environ["SDF_SDK"] + '/base/'

    if not path.exists(cwd + f):
        shutil.copy(pth + f, cwd + f)

    


if len(sys.argv) == 1 or sys.argv[1] in ("help", "--help"):
    print("""
Usage:
    || INSTALLATION
    opal install              
    opal check-install
    opal uninstall
    
    || PROJECT MANAGEMENT
    opal init
    opal pull (filename)
    opal list
""")
    sys.exit(0)

if sys.argv[1] == "check-install":
    if check_install():
        print("Opal SDK is installed")
    else:
        print("Opal SDK is not installed")
    sys.exit(0)

if sys.argv[1] == "install":
    update_bashrc()
    sys.exit(0)

if sys.argv[1] == "uninstall":
    uninstall()
    sys.exit(0)

if sys.argv[1] == "init":
    init()
    sys.exit(0)

if sys.argv[1] == "pull":
    if len(sys.argv) < 3:
        print("You need to specify a filename")
        sys.exit(0)
    pull(sys.argv[2])
    sys.exit(0)

if sys.argv[1] == "list":
    pth = os.environ["SDF_SDK"] + '/base/'
    for f in os.listdir(pth):
        if path.isfile(f): print(f)