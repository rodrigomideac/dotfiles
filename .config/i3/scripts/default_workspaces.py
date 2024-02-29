import os
import subprocess

monitor_1 = os.environ['MONITOR_1_NAME']
monitor_2 = os.environ['MONITOR_2_NAME']
monitor_3 = os.environ['MONITOR_3_NAME']
game_mode_activated = os.environ.get('GAME_MODE_ACTIVATED', None)

print(f"MONITOR_1_NAME: {monitor_1}")
print(f"MONITOR_2_NAME: {monitor_2}")
print(f"MONITOR_3_NAME: {monitor_3}")
print(f"GAME_MODE_ACTIVATED: {game_mode_activated}")

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

three_monitor_map_game_mode = {
        '1': monitor_1,
        '2': monitor_1,
        '3': monitor_2,
        '4': monitor_2,
        '5': monitor_2,
        '6': monitor_3,
        '7': monitor_2,
        '8': monitor_2,
        '9': monitor_2,
    }


def move_workspace_to_output(ws, output):
    cmd = f"i3-msg \"workspace {ws}, move workspace to output {output}\""
    return run_cmd(cmd)

def run_cmd(cmd):
    return subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, text=True).stdout.read()

def get_monitor_qty():
    cmd = f'xrandr | grep " connected " | wc -l'
    return int(run_cmd(cmd))

def process_monitor_map(monitor_map):
    for ws, output in monitor_map.items():
        result = move_workspace_to_output(ws, output)
        sleep(1)

qty = get_monitor_qty()
if qty == 2:
    monitor_map = two_monitor_map
elif qty == 3 and game_mode_activated is None:
    print('Game mode is not activated')
    monitor_map = three_monitor_map
elif qty == 3 and game_mode_activated:
    print('Game mode activated')
    monitor_map = three_monitor_map_game_mode
else:
    print('Monitor qty not supported!')

process_monitor_map(monitor_map)
