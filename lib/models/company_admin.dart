class CompanyAdmin {
  const CompanyAdmin({
    required this.id,
    required this.name,
    required this.email,
    required this.companyName,
  });

  final String id;
  final String name;
  final String email;
  final String companyName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'companyName': companyName,
      };

  factory CompanyAdmin.fromJson(Map<String, dynamic> json) => CompanyAdmin(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        companyName: json['companyName'] as String,
      );
}
