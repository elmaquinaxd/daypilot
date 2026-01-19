import 'package:serverpod/serverpod.dart';

class PingEndpoint extends Endpoint {
  Future<String> ping(Session session) async => 'pong';
}