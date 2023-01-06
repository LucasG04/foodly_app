import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/grocery_group.dart';

/// Provides the active shopping list id
final dataGroceryGroupsProvider =
    StateProvider<List<GroceryGroup>?>((_) => null);

/// Provides the supported sites to import dishes from
final dataSupportedImportSitesProvider = StateProvider<List<String>>((_) => []);
