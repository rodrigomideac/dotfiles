import os
import subprocess

monitor_1 = os.environ['MONITOR_1_NAME']
monitor_2 = os.environ['MONITOR_2_NAME']
monitor_3 = os.environ['MONITOR_3_NAME']

two_monitor_map = {
        '1': monitor_1,
        '2': monitor_1,
        '3': monitor_2,
        '4': monitor_2,
        '5': monitor_2,
        '6': monitor_2,
        '7': monitor_2,
        '8': monitor_2,
        '9': monitor_2,
    }

three_monitor_map = {
        '1': monitor_1,
        '2': monitor_1,
        '3': monitor_2,
        '4': monitor_1,
        '5': monitor_2,
        '6': monitor_2,
        '7': monitor_2,
        '8': monitor_3,
        '9': monitor_3,
    }


def move_workspace_to_output(ws, output):
    cmd = f"i3-msg '[workspace=\"{ws}\"]' move workspace to output {output}"
    return run_cmd(cmd)

def run_cmd(cmd):
    print(f"Running: {cmd}")
    return subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, text=True).stdout.read()

def get_monitor_qty():
    cmd = f'xrandr | grep " connected " | wc -l'
    return int(run_cmd(cmd))

def process_monitor_map(monitor_map):
    for ws, output in monitor_map.items():
        move_workspace_to_output(ws, output)


qty = get_monitor_qty()
if qty == 2:
    monitor_map = two_monitor_map
elif qty == 3:
    monitor_map = three_monitor_map
else:
    print('Monitor qty not supported!')

process_monitor_map(monitor_map)

