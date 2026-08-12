// PATH: Application.MAIN
PROGRAM MAIN
VAR
	// Controls
	bEnable : BOOL := FALSE;

	// IMU
	delta	 : LREAL := 0.002;
	alpha	 : LREAL := 0.98;
	accAlpha : LREAL := 0.9;
	roll	 : LREAL;
	pitch	 : LREAL;

	// PID controller
	setpoint		: LREAL := -4.35;
	Kp				: LREAL := 0.08;
	Ki				: LREAL := 0.01;
	Kd				: LREAL := 0.002;
	gyroAlpha		: LREAL := 0.1;
	integralLimit	: LREAL := 5.0;
	output			: LREAL;

	// Motor driver
	feed_forward : LREAL := 0.0;
	deadband	 : LREAL := 0.02;
	minPWM_LL	 : USINT := 27;
	minPWM_LR	 : USINT := 27;
	minPWM_RL	 : USINT := 35;
	minPWM_RR	 : USINT := 36;

	// Position controller
	posKp		: LREAL := 0.0005;
	posKd		: LREAL := 0.0;
	maxAdjust	: LREAL := 2.0;

	// Joystick scaling
	joySetpointScale : LREAL := 0.0001;
	turnScale        : LREAL := 0.0005;
	joyStartPrev     : BOOL;

	// Function blocks
	imu		: MPU6050;
	ang		: BalanceController;
	motor	: MotorDriver;
	pos		: PositionController;
	joy		: JoystickReceiver;

	state : INT := 0;
	state_message : STRING;

	// Safety
	cutoff : LREAL := 45; // degrees

	// Encoder reading
	encBuffer    : ARRAY[0..7] OF BYTE;
	leftCount    : DINT;
	rightCount   : DINT;

END_VAR
imu(
	accX := Gyro_MPU6050.lrAX,
	accY := Gyro_MPU6050.lrAY,
	accZ := Gyro_MPU6050.lrAZ,
	gyroX := Gyro_MPU6050.lrGX,
	gyroY := Gyro_MPU6050.lrGY,
	gyroZ := Gyro_MPU6050.lrGZ,
	delta := delta,
	alpha := alpha,
	accAlpha := accAlpha,
	roll => roll,
	pitch => pitch,
	);

pos(
	leftCount	:= leftCount,
	rightCount	:= rightCount,
	delta		:= delta,
	Kp			:= posKp,
	Kd			:= posKd,
	maxAdjust	:= maxAdjust,
	);

// Joystick always enabled so it keeps receiving packets
joy(
	bEnable	:= TRUE,
	port	:= 5000,
	);

// Start button (bit 7 = 0x0080) toggles robot enable on rising edge
IF (joy.Buttons AND 16#0080) <> 0 AND NOT joyStartPrev THEN
	bEnable := NOT bEnable;
END_IF
joyStartPrev := (joy.Buttons AND 16#0080) <> 0;

IF NOT bEnable THEN
	state := 0;
END_IF

ang(
	setpoint		:= setpoint + pos.setpointAdjust + INT_TO_LREAL(joy.LSY) * joySetpointScale,
	roll			:= imu.roll,
	pitch			:= imu.pitch,
	gyroY			:= Gyro_MPU6050.lrGY,
	delta			:= delta,
	Kp				:= Kp,
	Ki				:= Ki,
	Kd				:= Kd,
	gyroAlpha		:= gyroAlpha,
	integralLimit	:= integralLimit,
	output			=> output,
	);

motor(
	output		 := ang.output,
	turnAdjust	 := -INT_TO_LREAL(joy.RSX) * turnScale,
	feed_forward := feed_forward,
	deadband	 := deadband,
	minPWM_LL	 := minPWM_LL,
	minPWM_LR	 := minPWM_LR,
	minPWM_RL	 := minPWM_RL,
	minPWM_RR	 := minPWM_RR,
	);

teensy4(
	LEFT_RPWM := motor.LEFT_RPWM,
	LEFT_LPWM := motor.LEFT_LPWM,
	RIGHT_RPWM := motor.RIGHT_RPWM,
	RIGHT_LPWM := motor.RIGHT_LPWM,
	);

// Read encoder counts from Teensy (8 bytes: left 4 bytes big-endian, right 4 bytes big-endian)
teensy4.read(pbyBuffer := ADR(encBuffer), nBufferLen := 8);
leftCount  := UDINT_TO_DINT(SHL(BYTE_TO_UDINT(encBuffer[0]), 24) OR SHL(BYTE_TO_UDINT(encBuffer[1]), 16) OR SHL(BYTE_TO_UDINT(encBuffer[2]), 8) OR BYTE_TO_UDINT(encBuffer[3]));
rightCount := -UDINT_TO_DINT(SHL(BYTE_TO_UDINT(encBuffer[4]), 24) OR SHL(BYTE_TO_UDINT(encBuffer[5]), 16) OR SHL(BYTE_TO_UDINT(encBuffer[6]), 8) OR BYTE_TO_UDINT(encBuffer[7]));

CASE state OF
	0: // Off
		state_message := 'OFF';

		teensy4.LEFT_L_EN := FALSE;
		teensy4.LEFT_R_EN := FALSE;
		teensy4.RIGHT_L_EN := FALSE;
		teensy4.RIGHT_R_EN := FALSE;

		IF bEnable THEN
			state := 10;
		END_IF

	10: // Enabling
		state_message := 'ENABLING';

		teensy4.LEFT_L_EN := TRUE;
		teensy4.LEFT_R_EN := TRUE;
		teensy4.RIGHT_L_EN := TRUE;
		teensy4.RIGHT_R_EN := TRUE;

		state := 20;

	20: // Active
		state_message := 'ACTIVE';
		IF ABS(imu.pitch) > cutoff THEN
			state := 900;
		END_IF

	900: // Error
		state_message := 'error';

		teensy4.LEFT_L_EN := FALSE;
		teensy4.LEFT_R_EN := FALSE;
		teensy4.RIGHT_L_EN := FALSE;
		teensy4.RIGHT_R_EN := FALSE;

END_CASE