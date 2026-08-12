// PATH: Application.JoystickReceiver
FUNCTION_BLOCK JoystickReceiver
VAR_INPUT
	bEnable		: BOOL;
	port		: UINT := 5000;
END_VAR
VAR_OUTPUT
	LSX			: INT;	// Left stick X
	LSY			: INT;	// Left stick Y
	RSX			: INT;	// Right stick X
	RSY			: INT;	// Right stick Y
	LeftTrigger	: INT;	// Left trigger
	RightTrigger: INT;	// Right trigger
	DpadX		: INT;	// Dpad X
	DpadY		: INT;	// Dpad Y
	Buttons		: WORD;	// Button bitmask
	xConnected	: BOOL;
	xError		: BOOL;
END_VAR
VAR
	udpPeer		: NBS.UDP_Peer;
	udpReceive	: NBS.UDP_Receive;
	buffer		: ARRAY[0..17] OF BYTE;
	state		: INT := 0;
END_VAR
CASE state OF
	0: // Initialize UDP peer
		udpPeer(
			xEnable	:= bEnable,
			uiPort	:= port,
		);
		IF udpPeer.xActive THEN
			state := 10;
			xError := FALSE;
		ELSIF udpPeer.xError THEN
			xError := TRUE;
		END_IF

	10: // Receive packets
		udpPeer(
			xEnable	:= bEnable,
			uiPort	:= port,
		);

		IF NOT bEnable THEN
			state := 0;
			xConnected := FALSE;
		ELSIF udpPeer.xError THEN
			xError := TRUE;
			state := 0;
		END_IF

		udpReceive(
			xEnable	:= udpPeer.xActive,
			hPeer	:= udpPeer.hPeer,
			pData	:= ADR(buffer),
			szSize	:= SIZEOF(buffer),
		);

		IF udpReceive.xReady THEN
			xConnected := TRUE;
			LSX			:= WORD_TO_INT(BYTE_TO_WORD(buffer[0])  * 256 + BYTE_TO_WORD(buffer[1]));
			LSY			:= WORD_TO_INT(BYTE_TO_WORD(buffer[2])  * 256 + BYTE_TO_WORD(buffer[3]));
			RSX			:= WORD_TO_INT(BYTE_TO_WORD(buffer[4])  * 256 + BYTE_TO_WORD(buffer[5]));
			RSY			:= WORD_TO_INT(BYTE_TO_WORD(buffer[6])  * 256 + BYTE_TO_WORD(buffer[7]));
			LeftTrigger	:= WORD_TO_INT(BYTE_TO_WORD(buffer[8])  * 256 + BYTE_TO_WORD(buffer[9]));
			RightTrigger:= WORD_TO_INT(BYTE_TO_WORD(buffer[10]) * 256 + BYTE_TO_WORD(buffer[11]));
			DpadX		:= WORD_TO_INT(BYTE_TO_WORD(buffer[12]) * 256 + BYTE_TO_WORD(buffer[13]));
			DpadY		:= WORD_TO_INT(BYTE_TO_WORD(buffer[14]) * 256 + BYTE_TO_WORD(buffer[15]));
			Buttons		:= BYTE_TO_WORD(buffer[16]) * 256 + BYTE_TO_WORD(buffer[17]);
		END_IF

END_CASE