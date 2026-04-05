import '../config/tenant_service.dart';
import '../models/models.dart';

class RoleService {
  static const _roleKey = 'user_role';
  static const _teamKey = 'team_members';

  static UserRole getCurrentRole() {
    return userRoleFromCode(TenantService.currentConfig[_roleKey] as String?);
  }

  static List<TeamMember> getTeamMembers() {
    final raw = TenantService.currentConfig[_teamKey];
    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((item) => TeamMember.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<void> saveRoleSetup({
    required UserRole currentRole,
    required List<TeamMember> teamMembers,
  }) async {
    await TenantService.mergeTenantConfig({
      _roleKey: currentRole.code,
      _teamKey: teamMembers.map((member) => member.toJson()).toList(),
    });
  }

  static bool get canManageCatalog => getCurrentRole() == UserRole.owner;
  static bool get canManageSettings => getCurrentRole() == UserRole.owner;
  static bool get canManageSalesHistory => getCurrentRole() == UserRole.owner;
}
