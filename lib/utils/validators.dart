bool isValidBloodPressure(int systolic, int diastolic) {
  return systolic > 0 && 
         diastolic > 0 && 
         systolic < 300 && 
         diastolic < 200 &&
         systolic >= diastolic;  // Allow equal values for edge cases
}

bool isValidPulse(int pulse) {
  return pulse > 0 && pulse < 300;
}
