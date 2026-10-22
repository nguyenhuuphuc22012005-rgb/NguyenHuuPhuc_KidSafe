class ContactModel {
  final String id;
  final String childId;
  final String name;
  final String phone;
  final String relationship;
  final bool isSosContact;
  final String avatar;

  ContactModel({
    required this.id,
    required this.childId,
    required this.name,
    required this.phone,
    required this.relationship,
    this.isSosContact = false,
    this.avatar = 'avatar_contact',
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] ?? '',
      childId: json['childId'] ?? json['child_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      relationship: json['relationship'] ?? 'Người thân',
      isSosContact: json['isSosContact'] == true || json['is_sos_contact'] == true || json['is_sos_contact'] == 1,
      avatar: json['avatar'] ?? 'avatar_contact',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'child_id': childId,
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'isSosContact': isSosContact,
      'is_sos_contact': isSosContact,
      'avatar': avatar,
    };
  }

  ContactModel copyWith({
    String? id,
    String? childId,
    String? name,
    String? phone,
    String? relationship,
    bool? isSosContact,
    String? avatar,
  }) {
    return ContactModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      isSosContact: isSosContact ?? this.isSosContact,
      avatar: avatar ?? this.avatar,
    );
  }
}
