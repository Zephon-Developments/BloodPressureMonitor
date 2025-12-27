String formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

bool isValidBloodPressure(int systolic, int diastolic) {
  return systolic > 0 && 
         diastolic > 0 && 
         systolic < 300 && 
         diastolic < 200 &&
         systolic > diastolic;
}

bool isValidPulse(int pulse) {
  return pulse > 0 && pulse < 300;
}
