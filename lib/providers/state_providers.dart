import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/plan.dart';

/// Provides the active plan object.
final planProvider = StateProvider<Plan>((ref) => null);
