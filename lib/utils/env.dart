// ignore_for_file: prefer_const_declarations, avoid_classes_with_only_static_members

import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'LUNIX_API_KEY', obfuscate: true)
  static final lunixApiKey = _Env.lunixApiKey;

  @EnviedField(varName: 'REVENUECAT_APPLE_KEY', obfuscate: true)
  static final revenuecatAppleKey = _Env.revenuecatAppleKey;

  @EnviedField(varName: 'REVENUECAT_GOOGLE_KEY', obfuscate: true)
  static final revenuecatGoogleKey = _Env.revenuecatGoogleKey;
}
