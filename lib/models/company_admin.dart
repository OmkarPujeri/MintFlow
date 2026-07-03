class CompanyAdmin {
  const CompanyAdmin({
    required this.id,
    required this.name,
    required this.email,
    required this.companyName,
    this.brandBio = '',
    this.brandWebsite = '',
    this.brandLogoUrl = '',
  });

  final String id;
  final String name;
  final String email;
  final String companyName;
  final String brandBio;
  final String brandWebsite;
  final String brandLogoUrl;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'companyName': companyName,
        'brandBio': brandBio,
        'brandWebsite': brandWebsite,
        'brandLogoUrl': brandLogoUrl,
      };

  factory CompanyAdmin.fromJson(Map<String, dynamic> json) => CompanyAdmin(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        companyName: json['companyName'] as String,
        brandBio: (json['brandBio'] as String?) ?? '',
        brandWebsite: (json['brandWebsite'] as String?) ?? '',
        brandLogoUrl: (json['brandLogoUrl'] as String?) ?? '',
      );
}
