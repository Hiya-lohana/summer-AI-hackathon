class Contact {
  final int? id;
  final String name;
  final String phone;
  final String relation;

  Contact({
    this.id,
    required this.name,
    required this.phone,
    required this.relation,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      relation: json['relation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'name': name,
      'phone': phone,
      'relation': relation,
    };
    if (id != null) {
      data['id'] = id;
    }
    return data;
  }
}
