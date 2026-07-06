class RoomModel {
  final String id;
  final String nome;
  final String? indirizzo;

  RoomModel({
    required this.id,
    required this.nome,
    this.indirizzo,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id']?.toString() ?? '',
      nome: json['nome'] as String? ?? 'Stanza senza nome',
      indirizzo: json['indirizzo'] as String? ?? json['descrizione'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'indirizzo': indirizzo,
    };
  }
}
