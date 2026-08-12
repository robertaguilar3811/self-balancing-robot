// PATH: Application.MotorDriver
FUNCTION_BLOCK MotorDriver
VAR_INPUT
	output		 : LREAL;
	turnAdjust	 : LREAL := 0.0;
	feed_forward : LREAL := 0.0;
	deadband	 : LREAL := 0.02;
	minPWM_LL	 : USINT := 10;
	minPWM_LR	 : USINT := 11;
	minPWM_RL	 : USINT := 13;
	minPWM_RR	 : USINT := 13;
END_VAR
VAR_OUTPUT
    RIGHT_RPWM : USINT;
    RIGHT_LPWM : USINT;
    LEFT_RPWM  : USINT;
    LEFT_LPWM  : USINT;
END_VAR
VAR
	baseOutput : LREAL;
	leftOut    : LREAL;
	rightOut   : LREAL;
	leftPwm    : UINT;
	rightPwm   : UINT;
END_VAR
// Apply deadband and feed_forward, preserving sign
// Negative output = forward (matches original convention)
IF ABS(output) > deadband THEN
	IF output < 0.0 THEN
		baseOutput := -(ABS(output) + feed_forward);
	ELSE
		baseOutput := ABS(output) + feed_forward;
	END_IF
ELSE
	baseOutput := 0.0;
END_IF

IF baseOutput >  1.0 THEN baseOutput :=  1.0; END_IF
IF baseOutput < -1.0 THEN baseOutput := -1.0; END_IF

// Per-side output: negative = forward, positive = backward
// turnAdjust > 0 = turn right: left goes more forward (more negative), right goes less forward
leftOut  := baseOutput - turnAdjust;
rightOut := baseOutput + turnAdjust;

IF leftOut  >  1.0 THEN leftOut  :=  1.0; END_IF
IF leftOut  < -1.0 THEN leftOut  := -1.0; END_IF
IF rightOut >  1.0 THEN rightOut :=  1.0; END_IF
IF rightOut < -1.0 THEN rightOut := -1.0; END_IF

// Left motor: negative = forward (LL), positive = backward (LR)
IF leftOut < 0.0 THEN
	leftPwm := LREAL_TO_UINT(ABS(leftOut) * 255);
	IF leftPwm + minPWM_LL > 255 THEN LEFT_LPWM := 255; ELSE LEFT_LPWM := UINT_TO_USINT(leftPwm) + minPWM_LL; END_IF
	LEFT_RPWM := 0;
ELSIF leftOut > 0.0 THEN
	leftPwm := LREAL_TO_UINT(leftOut * 255);
	IF leftPwm + minPWM_LR > 255 THEN LEFT_RPWM := 255; ELSE LEFT_RPWM := UINT_TO_USINT(leftPwm) + minPWM_LR; END_IF
	LEFT_LPWM := 0;
ELSE
	LEFT_LPWM := 0;
	LEFT_RPWM := 0;
END_IF

// Right motor: negative = forward (RR), positive = backward (RL)
IF rightOut < 0.0 THEN
	rightPwm := LREAL_TO_UINT(ABS(rightOut) * 255);
	IF rightPwm + minPWM_RR > 255 THEN RIGHT_RPWM := 255; ELSE RIGHT_RPWM := UINT_TO_USINT(rightPwm) + minPWM_RR; END_IF
	RIGHT_LPWM := 0;
ELSIF rightOut > 0.0 THEN
	rightPwm := LREAL_TO_UINT(rightOut * 255);
	IF rightPwm + minPWM_RL > 255 THEN RIGHT_LPWM := 255; ELSE RIGHT_LPWM := UINT_TO_USINT(rightPwm) + minPWM_RL; END_IF
	RIGHT_RPWM := 0;
ELSE
	RIGHT_RPWM := 0;
	RIGHT_LPWM := 0;
END_IF