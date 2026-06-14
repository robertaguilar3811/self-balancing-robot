from setuptools import find_packages, setup

package_name = 'joy_modbus_bridge'

setup(
    name=package_name,
    version='0.0.1',
    packages=find_packages(exclude=['test']),
    data_files=[
        ('share/ament_index/resource_index/packages', ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
        ('share/' + package_name + '/launch', ['launch/joy_modbus_bridge_launch.py']),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='rj',
    maintainer_email='robertaguilar3811@gmail.com',
    description='Forwards ROS2 joy messages to a CODESYS runtime via Modbus TCP',
    license='MIT',
    tests_require=['pytest'],
    entry_points={
        'console_scripts': [
            'joy_modbus_bridge_node = joy_modbus_bridge.joy_modbus_bridge_node:main',
        ],
    },
)
