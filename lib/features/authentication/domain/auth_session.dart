class AuthSession {
  final String agentName;
  final DateTime signedInAt;

  const AuthSession({
    required this.agentName,
    required this.signedInAt,
  });

  Map<String, dynamic> toJson() => {
        'agentName': agentName,
        'signedInAt': signedInAt.toIso8601String(),
      };

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        agentName: json['agentName'] as String,
        signedInAt: DateTime.parse(json['signedInAt'] as String),
      );
}
