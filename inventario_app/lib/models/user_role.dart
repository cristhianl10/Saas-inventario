enum UserRole { owner, seller }

extension UserRoleX on UserRole {
  String get code => this == UserRole.owner ? 'owner' : 'seller';

  String get label => this == UserRole.owner ? 'Dueno' : 'Vendedor';

  String get description => this == UserRole.owner
      ? 'Acceso completo a catalogo, reportes, configuracion y proveedores.'
      : 'Puede vender y consultar informacion, pero no cambiar configuracion ni eliminar datos.';
}

UserRole userRoleFromCode(String? code) {
  switch (code) {
    case 'seller':
      return UserRole.seller;
    case 'owner':
    default:
      return UserRole.owner;
  }
}

class TeamMember {
  final String name;
  final UserRole role;

  TeamMember({required this.name, required this.role});

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      name: (json['name'] as String? ?? '').trim(),
      role: userRoleFromCode(json['role'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'role': role.code,
    };
  }
}
