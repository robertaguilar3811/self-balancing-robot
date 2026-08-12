// PATH: Application.BalanceController
FUNCTION_BLOCK BalanceController
VAR_INPUT
	setpoint		: LREAL := 0.0;
	roll			: LREAL;
	pitch			: LREAL;
	gyroY			: LREAL;
	delta			: LREAL;
	Kp				: LREAL;
	Ki				: LREAL;
	Kd				: LREAL;
	gyroAlpha		: LREAL := 0.1;
	integralLimit	: LREAL := 1.0;
END_VAR
VAR_OUTPUT
	output		: LREAL;
END_VAR
VAR
	error			: LREAL;
	prevError		: LREAL := 0.0;
	integral		: LREAL := 0.0;
	gyroYFiltered	: LREAL := 0.0;
END_VAR
// Calculate error
error := setpoint - pitch;

// Integral term with anti-windup clamp
integral := integral + error * delta;
IF integral > integralLimit THEN
    integral := integralLimit;
ELSIF integral < -integralLimit THEN
    integral := -integralLimit;
END_IF

// Low-pass filter on gyroY
gyroYFiltered := gyroAlpha * gyroY + (1.0 - gyroAlpha) * gyroYFiltered;

// PID output
output := Kp * error + Ki * integral - Kd * gyroYFiltered;

// Save error for next cycle
prevError := error;