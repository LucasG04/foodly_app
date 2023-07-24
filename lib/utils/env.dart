// ignore_for_file: prefer_const_declarations, avoid_classes_with_only_static_members, avoid_dynamic_calls

import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'LUNIX_API_KEY', obfuscate: true)
  static final String lunixApiKey = _Env.lunixApiKey;

  @EnviedField(varName: 'LUNIX_API_KEY_DEV', obfuscate: true)
  static final String lunixApiKeyDev = _Env.lunixApiKeyDev;

  @EnviedField(varName: 'REVENUECAT_APPLE_KEY', obfuscate: true)
  static final String revenuecatAppleKey = _Env.revenuecatAppleKey;

  @EnviedField(varName: 'REVENUECAT_GOOGLE_KEY', obfuscate: true)
  static final String revenuecatGoogleKey = _Env.revenuecatGoogleKey;
}
