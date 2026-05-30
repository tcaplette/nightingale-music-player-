class ApPublicKey {
  const ApPublicKey({
    required this.id,
    required this.owner,
    required this.publicKeyPem,
  });

  final String id;
  final String owner;
  final String publicKeyPem;

  factory ApPublicKey.fromJson(Map<String, dynamic> json) => ApPublicKey(
        id: json['id'] as String,
        owner: json['owner'] as String,
        publicKeyPem: json['publicKeyPem'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner': owner,
        'publicKeyPem': publicKeyPem,
      };
}
