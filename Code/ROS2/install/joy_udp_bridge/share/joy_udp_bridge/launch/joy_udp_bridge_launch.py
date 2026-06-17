from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description():
    return LaunchDescription([
        Node(
            package='joy',
            executable='joy_node',
            name='joy_node',
            parameters=[{'dev': '/dev/input/js0'}],
        ),
        Node(
            package='joy_udp_bridge',
            executable='joy_udp_bridge_node',
            name='joy_udp_bridge',
            parameters=[{
                'codesys_ip': '192.168.1.72',
                'codesys_port': 5000,
            }],
        ),
    ])
