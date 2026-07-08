class UserModel {
  final int id;
  final String nome;
  final String cognome;
  final String email;
  final String ruolo;
  final String ruoloEtichetta;
  final bool privacyAccettata;
  final bool attivoChatEnabled;
  final bool isHaccpPreposto;
  final String? apiToken; // Bearer token per autenticazione API mobile

  UserModel({
    required this.id,
    required this.nome,
    required this.cognome,
    required this.email,
    required this.ruolo,
    required this.ruoloEtichetta,
    required this.privacyAccettata,
    this.attivoChatEnabled = true,
    this.isHaccpPreposto = false,
    this.apiToken,
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
      attivoChatEnabled: json['attivo_chat'] as bool? ?? true,
      isHaccpPreposto: json['is_haccp_preposto'] as bool? ?? false,
      apiToken: json['api_token'] as String?,
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
      'attivo_chat': attivoChatEnabled,
      'is_haccp_preposto': isHaccpPreposto,
      if (apiToken != null) 'api_token': apiToken,
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
    bool? attivoChatEnabled,
    bool? isHaccpPreposto,
    String? apiToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cognome: cognome ?? this.cognome,
      email: email ?? this.email,
      ruolo: ruolo ?? this.ruolo,
      ruoloEtichetta: ruoloEtichetta ?? this.ruoloEtichetta,
      privacyAccettata: privacyAccettata ?? this.privacyAccettata,
      attivoChatEnabled: attivoChatEnabled ?? this.attivoChatEnabled,
      isHaccpPreposto: isHaccpPreposto ?? this.isHaccpPreposto,
      apiToken: apiToken ?? this.apiToken,
    );
  }

  String get nomeCompleto => '$nome $cognome'.trim();
}
