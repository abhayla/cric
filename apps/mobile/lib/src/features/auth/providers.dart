import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/notifiers/auth_notifier.dart';

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthUiState>(AuthNotifier.new);
