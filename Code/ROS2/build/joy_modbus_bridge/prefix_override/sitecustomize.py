import sys
if sys.prefix == '/usr':
    sys.real_prefix = sys.prefix
    sys.prefix = sys.exec_prefix = '/home/rj/Documents/SelfBalancingRobot/Code/ROS2/install/joy_modbus_bridge'
