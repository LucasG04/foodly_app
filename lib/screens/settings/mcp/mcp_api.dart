import '../../../models/mcp_connection.dart';
import '../../../services/lunix_api_service.dart';

/// Everything the AI-assistants sheet loads or changes. Tests pass a fake.
class McpApi {
  const McpApi();

  String get serverUrl => LunixApiService.mcpEndpoint;

  Future<List<McpConnection>> connections() =>
      LunixApiService.getMcpConnections();

  /// Null if the user has no API key.
  Future<DateTime?> apiKeyCreatedAt() => LunixApiService.getMcpTokenCreatedAt();

  Future<void> disconnect(String id) => LunixApiService.deleteMcpConnection(id);
}
