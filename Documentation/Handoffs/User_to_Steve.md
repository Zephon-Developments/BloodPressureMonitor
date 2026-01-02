
# User Feedback & Feature Requests

## API Updates

### withAlpha

Update color.withAlpha to color.withValues throughout the codebase

## UI Polish

### lib/views/sleep/add_sleep_view.dart

Color inconsistency: Light Sleep slider uses Colors.blue but should use Colors.lightBlue to match the sleep history display (line 184 in sleep_history_view.dart), the documentation, and the code review. This inconsistency means the colors shown during entry won't match the colors shown in the history view, which could confuse users.