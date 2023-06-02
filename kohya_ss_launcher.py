import os, time


def launch_kohya_ss():
    launch_string = 'cd /workspace/kohya_ss && nohup ./gui.sh --listen 0.0.0.0 --server_port 3010'
    print(f'Launching Kohya_ss: {launch_string}')
    os.system(launch_string)
    print('Kohya_ss Process is ending. Relaunch by running:\n')
    print('   python3 /workspace/kohya_ss_launcher.py')


if __name__ == '__main__':
    launch_kohya_ss()