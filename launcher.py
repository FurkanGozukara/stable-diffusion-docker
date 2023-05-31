import os, time

launch_string = '/workspace/stable-diffusion-webui/webui.sh -f'
print(f'Launching Stable Diffusion Web UI: {launch_string}')
os.system(launch_string)
print('Stable Diffusion Web UI Process is ending. Relaunch by running:\n')
print('   python3 /workspace/stable-diffusion-webui/launcher.py')