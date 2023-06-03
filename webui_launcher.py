#!/usr/bin/env python3
import os, time


def launch_web_ui():
    launch_string = '/workspace/stable-diffusion-webui/webui.sh -f'
    print(f'Launching Stable Diffusion Web UI: {launch_string}')
    os.system(launch_string)
    print('Stable Diffusion Web UI Process is ending. Relaunch by running:\n')
    print('   python3 /workspace/webui_launcher.py')


if __name__ == '__main__':
    launch_web_ui()