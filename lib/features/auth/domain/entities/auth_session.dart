class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUser user;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.phone,
    required this.roles,
    required this.activeMode,
    this.name,
    this.email,
    this.zaloPhone,
    this.avatarUrl,
    this.createdAt,
    this.profileComplete = false,
    this.status = 'ACTIVE',
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    phone: json['phone'] as String? ?? '',
    name: json['name'] as String?,
    email: json['email'] as String?,
    zaloPhone: json['zalo_phone'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    profileComplete: json['profile_complete'] as bool? ?? false,
    status: json['status'] as String? ?? 'ACTIVE',
    roles: (json['roles'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(),
    activeMode: json['active_mode'] as String? ?? 'TENANT',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'name': name,
    'email': email,
    'zalo_phone': zaloPhone,
    'avatar_url': avatarUrl,
    'created_at': createdAt?.toIso8601String(),
    'profile_complete': profileComplete,
    'status': status,
    'roles': roles,
    'active_mode': activeMode,
  };

  final String id;
  final String phone;
  final String? name;
  final String? email;
  final String? zaloPhone;
  final String? avatarUrl;
  final DateTime? createdAt;
  final bool profileComplete;
  final String status;
  final List<String> roles;
  final String activeMode;
}

// phần xác định role
extension AuthUserRole on AuthUser {
  bool get hasTenantRole {
    return roles.contains('TENANT');
  }

  bool get hasLandlordRole {
    return roles.any(
      const {'LANDLORD', 'LANDLORD_STAFF', 'ORGANIZATION_OWNER'}.contains,
    );
  }

  String? get availableLandlordMode {
    const landlordRoles = {'LANDLORD', 'LANDLORD_STAFF', 'ORGANIZATION_OWNER'};
    for (final role in roles) {
      if (landlordRoles.contains(role)) return role;
    }
    return null;
  }

  bool get isTenantMode {
    return activeMode == 'TENANT';
  }

  bool get isLandlordMode {
    return const {
      'LANDLORD',
      'LANDLORD_STAFF',
      'ORGANIZATION_OWNER',
    }.contains(activeMode);
  }
}
