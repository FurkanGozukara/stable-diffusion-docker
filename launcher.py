import os, time

launch_string = '/workspace/stable-diffusion-webui/webui.sh -f'
print(f'Launching: {launch_string}')
os.system(launch_string)
print('Launcher: Process is ending. Relaunch by running')
    n += 1
    time.sleep(2)