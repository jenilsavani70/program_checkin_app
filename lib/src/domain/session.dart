import 'package:equatable/equatable.dart';

class Session extends Equatable {
  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresAt];
}
