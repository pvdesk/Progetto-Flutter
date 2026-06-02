class UserModel {
  final int id;
  final String nome;
  final String cognome;
  final String email;
  final String ruolo;
  final String ruoloEtichetta;
  final bool privacyAccettata;

  UserModel({
    required this.id,
    required this.nome,
    required this.cognome,
    required this.email,
    required this.ruolo,
    required this.ruoloEtichetta,
    required this.privacyAccettata,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      nome: json['nome'] as String? ?? '',
      cognome: json['cognome'] as String? ?? '',
      email: json['email'] as String? ?? '',
      ruolo: json['ruolo'] as String? ?? 'operatore',
      ruoloEtichetta: json['ruolo_etichetta'] as String? ?? 'Operatore',
      privacyAccettata: json['privacy_accettata'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'cognome': cognome,
      'email': email,
      'ruolo': ruolo,
      'ruolo_etichetta': ruoloEtichetta,
      'privacy_accettata': privacyAccettata,
    };
  }

  UserModel copyWith({
    int? id,
    String? nome,
    String? cognome,
    String? email,
    String? ruolo,
    String? ruoloEtichetta,
    bool? privacyAccettata,
  }) {
    return UserModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cognome: cognome ?? this.cognome,
      email: email ?? this.email,
      ruolo: ruolo ?? this.ruolo,
      ruoloEtichetta: ruoloEtichetta ?? this.ruoloEtichetta,
      privacyAccettata: privacyAccettata ?? this.privacyAccettata,
    );
  }

  String get nomeCompleto => '$nome $cognome'.trim();
}
