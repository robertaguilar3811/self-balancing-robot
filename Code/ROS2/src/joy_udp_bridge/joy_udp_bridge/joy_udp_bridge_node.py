import socket
import struct
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Joy

SCALE = 10000


class JoyUdpBridgeNode(Node):
    def __init__(self):
        super().__init__('joy_udp_bridge')

        self.declare_parameter('codesys_ip', '192.168.1.72')
        self.declare_parameter('codesys_port', 5000)

        self._ip = self.get_parameter('codesys_ip').get_parameter_value().string_value
        self._port = self.get_parameter('codesys_port').get_parameter_value().integer_value

        self._sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.get_logger().info(f'Sending UDP to {self._ip}:{self._port}')

        self.create_subscription(Joy, '/joy', self._joy_callback, 10)

    # ------------------------------------------------------------------
    # Xbox 360 axis layout (xpad driver):
    #   axes[0] = Left Stick X   (-1=left,  1=right)
    #   axes[1] = Left Stick Y   (-1=down,  1=up)
    #   axes[2] = LT             ( 1=released, -1=pressed)
    #   axes[3] = Right Stick X  (-1=left,  1=right)
    #   axes[4] = Right Stick Y  (-1=down,  1=up)
    #   axes[5] = RT             ( 1=released, -1=pressed)
    #   axes[6] = D-pad X        (-1=left,  1=right)
    #   axes[7] = D-pad Y        (-1=down,  1=up)
    #
    # UDP packet: 18 bytes, 9 × INT16 big-endian (struct '>9h')
    #   [0] Left Stick X   -10000..10000
    #   [1] Left Stick Y   -10000..10000
    #   [2] Right Stick X  -10000..10000
    #   [3] Right Stick Y  -10000..10000
    #   [4] LT             0..10000 (0=released, 10000=fully pressed)
    #   [5] RT             0..10000
    #   [6] D-pad X        -10000..10000
    #   [7] D-pad Y        -10000..10000
    #   [8] Buttons        bitmask (bit 0=A, 1=B, 2=X, 3=Y, 4=LB, 5=RB,
    #                               6=Back, 7=Start, 8=Xbox, 9=LS, 10=RS)
    # ------------------------------------------------------------------

    def _joy_callback(self, msg: Joy):
        axes = msg.axes
        buttons = msg.buttons

        def axis(i):
            return self._scale(axes[i]) if len(axes) > i else 0

        def trigger(i):
            return self._trigger(axes[i]) if len(axes) > i else 0

        btn_mask = 0
        for i, b in enumerate(buttons[:15]):
            btn_mask |= (int(b) << i)

        packet = struct.pack('>9h',
            axis(0), axis(1),
            axis(3), axis(4),
            trigger(2), trigger(5),
            axis(6), axis(7),
            btn_mask,
        )

        self._sock.sendto(packet, (self._ip, self._port))

    def _scale(self, value: float) -> int:
        return int(max(-1.0, min(1.0, value)) * SCALE)

    def _trigger(self, value: float) -> int:
        # Triggers: 1.0=released, -1.0=fully pressed → remap to 0..10000
        return int((1.0 - max(-1.0, min(1.0, value))) / 2.0 * SCALE)

    def destroy_node(self):
        self._sock.close()
        super().destroy_node()


def main(args=None):
    rclpy.init(args=args)
    node = JoyUdpBridgeNode()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()
