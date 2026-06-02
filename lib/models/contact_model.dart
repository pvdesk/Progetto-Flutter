class ContactModel {
  final int id;
  final String nome;
  final String cognome;
  final String email;
  final String ruolo;
  final String ruoloEtichetta;
  final int unreadCount;

  ContactModel({
    required this.id,
    required this.nome,
    required this.cognome,
    required this.email,
    required this.ruolo,
    required this.ruoloEtichetta,
    required this.unreadCount,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as int,
      nome: json['nome'] as String? ?? '',
      cognome: json['cognome'] as String? ?? '',
      email: json['email'] as String? ?? '',
      ruolo: json['ruolo'] as String? ?? 'operatore',
      ruoloEtichetta: json['ruolo_etichetta'] as String? ?? 'Operatore',
      unreadCount: json['unread_count'] as int? ?? 0,
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
      'unread_count': unreadCount,
    };
  }

  String get nomeCompleto => '$nome $cognome'.trim();
}
