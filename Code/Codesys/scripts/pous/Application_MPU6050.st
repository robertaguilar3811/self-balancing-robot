// PATH: Application.MPU6050
FUNCTION_BLOCK MPU6050
VAR_INPUT
    accX : LREAL;    // Accelerometer X
    accY : LREAL;    // Accelerometer Y
    accZ : LREAL;    // Accelerometer Z
    gyroX : LREAL;   // Gyro X (°/s)
    gyroY : LREAL;   // Gyro Y (°/s)
	gyroZ : LREAL;   // Gyro Z (°/s)
    delta : LREAL;   // Cycle time in seconds
    alpha : LREAL;   // Filter coefficient (default 0.98)
    accAlpha : LREAL := 0.9; // Accelerometer low-pass coefficient
END_VAR
VAR_OUTPUT
    roll : LREAL;    // Filtered roll in degrees
    pitch : LREAL;   // Filtered pitch in degrees
END_VAR
VAR
    rollAcc : LREAL;
    pitchAcc : LREAL;
    rollAccFiltered  : LREAL := 0;
    pitchAccFiltered : LREAL := 0;
    rollPrev : LREAL := 0;
    pitchPrev : LREAL := 0;
END_VAR
//rollAcc  := MATH.atan2_func(Gyro_MPU6050.lrAY, SQRT((Gyro_MPU6050.lrAX*Gyro_MPU6050.lrAX) + (Gyro_MPU6050.lrAZ*Gyro_MPU6050.lrAZ))) * 180.0 / MATH.PI;
//pitchAcc := MATH.atan2_func(-Gyro_MPU6050.lrAX, SQRT((Gyro_MPU6050.lrAY*Gyro_MPU6050.lrAY) + (Gyro_MPU6050.lrAZ*Gyro_MPU6050.lrAZ))) * 180.0 / MATH.PI;

// Accelerometer angles
rollAcc  := MATH.atan2_func(accY, SQRT((accX*accX) + (accZ*accZ))) * 180.0 / MATH.PI;
pitchAcc := MATH.atan2_func(-accX, SQRT((accY*accY) + (accZ*accZ))) * 180.0 / MATH.PI;

// Low-pass filter on accelerometer angles to reduce vibration noise
rollAccFiltered  := accAlpha * rollAccFiltered  + (1.0 - accAlpha) * rollAcc;
pitchAccFiltered := accAlpha * pitchAccFiltered + (1.0 - accAlpha) * pitchAcc;

// Complementary filter with gyro integration
roll  := alpha * (rollPrev + gyroX * delta) + (1 - alpha) * rollAccFiltered;
pitch := alpha * (pitchPrev + gyroY * delta) + (1 - alpha) * pitchAccFiltered;

// Save previous values for next cycle
rollPrev := roll;
pitchPrev := pitch;