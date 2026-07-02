class TipoAttrezzatura {
  final int id;
  final String sezione;
  final String nome;
  final String label;
  final bool attiva;

  TipoAttrezzatura({
    required this.id,
    required this.sezione,
    required this.nome,
    required this.label,
    required this.attiva,
  });

  factory TipoAttrezzatura.fromJson(Map<String, dynamic> json) {
    return TipoAttrezzatura(
      id: json['id'],
      sezione: json['sezione'] ?? '',
      nome: json['nome'] ?? '',
      label: json['label'] ?? '',
      attiva: json['attiva'] == 1 || json['attiva'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sezione': sezione,
      'nome': nome,
      'label': label,
      'attiva': attiva ? 1 : 0,
    };
  }
}
