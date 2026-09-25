class Mahatma {
  String id;
  String code;
  String letterNo;
  String nameEnglish;
  String nameGujarati;
  String nameHindi;
  String samuday;
  String sevakName;
  String contactPerson;
  String contactNumber;
  String thanaNo;
  DateTime? selectedDate;
  String districtIncharge;
  String salutation;
  bool active;

  Mahatma({
    required this.id,
    required this.code,
    this.letterNo = '',
    required this.nameEnglish,
    this.nameGujarati = '',
    this.nameHindi = '',
    required this.samuday,
    this.sevakName = '',
    this.contactPerson = '',
    required this.contactNumber,
    this.thanaNo = '',
    this.selectedDate,
    this.districtIncharge = '',
    this.salutation = 'Shri',
    this.active = true,
  });

  Mahatma copyWith({
    String? id,
    String? code,
    String? letterNo,
    String? nameEnglish,
    String? nameGujarati,
    String? nameHindi,
    String? samuday,
    String? sevakName,
    String? contactPerson,
    String? contactNumber,
    String? thanaNo,
    DateTime? selectedDate,
    String? districtIncharge,
    String? salutation,
    bool? active,
  }) {
    return Mahatma(
      id: id ?? this.id,
      code: code ?? this.code,
      letterNo: letterNo ?? this.letterNo,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      nameGujarati: nameGujarati ?? this.nameGujarati,
      nameHindi: nameHindi ?? this.nameHindi,
      samuday: samuday ?? this.samuday,
      sevakName: sevakName ?? this.sevakName,
      contactPerson: contactPerson ?? this.contactPerson,
      contactNumber: contactNumber ?? this.contactNumber,
      thanaNo: thanaNo ?? this.thanaNo,
      selectedDate: selectedDate ?? this.selectedDate,
      districtIncharge: districtIncharge ?? this.districtIncharge,
      salutation: salutation ?? this.salutation,
      active: active ?? this.active,
    );
  }
}

class Vihar {
  String id;
  String mahatmaId;
  String mahatmaName;
  String startLocation;
  String endLocation;
  DateTime startDate;
  DateTime endDate;
  String status; // e.g. Planned, In Progress, Completed
  String notes;
  String letterNo;
  String salutation;
  String thanaNo;
  String sevakName;
  String contactNumber;
  bool active;
  List<ViharRoute> routes;

  Vihar({
    required this.id,
    required this.mahatmaId,
    required this.mahatmaName,
    required this.startLocation,
    required this.endLocation,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.notes = '',
    this.letterNo = '',
    this.salutation = 'Shri',
    this.thanaNo = '',
    this.sevakName = '',
    this.contactNumber = '',
    this.active = true,
    List<ViharRoute>? routes,
  }) : routes = routes ?? [];

  Vihar copyWith({
    String? id,
    String? mahatmaId,
    String? mahatmaName,
    String? startLocation,
    String? endLocation,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? notes,
    String? letterNo,
    String? salutation,
    String? thanaNo,
    String? sevakName,
    String? contactNumber,
    bool? active,
    List<ViharRoute>? routes,
  }) {
    return Vihar(
      id: id ?? this.id,
      mahatmaId: mahatmaId ?? this.mahatmaId,
      mahatmaName: mahatmaName ?? this.mahatmaName,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      letterNo: letterNo ?? this.letterNo,
      salutation: salutation ?? this.salutation,
      thanaNo: thanaNo ?? this.thanaNo,
      sevakName: sevakName ?? this.sevakName,
      contactNumber: contactNumber ?? this.contactNumber,
      active: active ?? this.active,
      routes: routes ?? List.from(this.routes),
    );
  }
}

class ViharRoute {
  String id;
  String viharId;
  String viharName;
  DateTime viharDate;
  String fromLocation;
  String toLocation;
  String district;
  String districtInchargeInfo;
  double distanceKm;
  String status; // e.g., Upcoming, Active, Completed

  ViharRoute({
    required this.id,
    this.viharId = '',
    this.viharName = '',
    required this.viharDate,
    required this.fromLocation,
    required this.toLocation,
    required this.district,
    required this.districtInchargeInfo,
    this.distanceKm = 0.0,
    this.status = 'Upcoming',
  });

  ViharRoute copyWith({
    String? id,
    String? viharId,
    String? viharName,
    DateTime? viharDate,
    String? fromLocation,
    String? toLocation,
    String? district,
    String? districtInchargeInfo,
    double? distanceKm,
    String? status,
  }) {
    return ViharRoute(
      id: id ?? this.id,
      viharId: viharId ?? this.viharId,
      viharName: viharName ?? this.viharName,
      viharDate: viharDate ?? this.viharDate,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      district: district ?? this.district,
      districtInchargeInfo: districtInchargeInfo ?? this.districtInchargeInfo,
      distanceKm: distanceKm ?? this.distanceKm,
      status: status ?? this.status,
    );
  }
}

class Samuday {
  String id;
  String name;
  String code;
  String status; // 'active' / 'inactive'
  bool active;

  Samuday({
    required this.id,
    required this.name,
    this.code = '',
    this.status = 'active',
    bool? active,
  }) : active = active ?? (status == 'active');
}

class District {
  String id;
  String name;
  String nameEnglish;
  String nameGujarati;
  String nameHindi;
  String inchargeId;
  String inchargeName;
  String stateId;
  String state;
  String status; // 'active' / 'inactive'
  bool active;

  District({
    required this.id,
    required this.name,
    this.nameEnglish = '',
    this.nameGujarati = '',
    this.nameHindi = '',
    this.inchargeId = '',
    this.inchargeName = '',
    this.stateId = '',
    required this.state,
    this.status = 'active',
    bool? active,
  }) : active = active ?? (status == 'active');
}

class DistrictIncharge {
  String id;
  String firstName;
  String lastName;
  String name;
  String phone;
  String email;
  String password;
  String district;
  String contactNumber;
  String stage; // 'active' / 'inactive'
  bool active;

  DistrictIncharge({
    required this.id,
    this.firstName = '',
    this.lastName = '',
    String? name,
    this.phone = '',
    this.email = '',
    this.password = '',
    this.district = 'Gujarat',
    String? contactNumber,
    this.stage = 'active',
    bool? active,
  })  : name = name ?? ('$firstName $lastName'.trim().isNotEmpty ? '$firstName $lastName'.trim() : 'Incharge #$id'),
        contactNumber = contactNumber ?? phone,
        active = active ?? (stage == 'active');
}

class StateModel {
  String id;
  String name;
  String nameEnglish;
  String nameGujarati;
  String nameHindi;
  String code;
  String country;
  String status; // 'active' / 'inactive'
  bool active;

  StateModel({
    required this.id,
    required this.name,
    this.nameEnglish = '',
    this.nameGujarati = '',
    this.nameHindi = '',
    this.code = '',
    this.country = 'India',
    this.status = 'active',
    bool? active,
  }) : active = active ?? (status == 'active');
}

class Salutation {
  String id;
  String title;
  String nameEnglish;
  String nameGujarati;
  String nameHindi;
  String salutationPrefix; // 'd.g.p.', 'c.p.', 's.p.'
  String groupId;
  String groupName;
  String districtId;
  String districtName;
  String stateId;
  String stateName;
  String groupType; // 'state' / 'district'
  String status; // 'active' / 'inactive'
  bool active;

  Salutation({
    required this.id,
    required this.title,
    this.nameEnglish = '',
    this.nameGujarati = '',
    this.nameHindi = '',
    this.salutationPrefix = '',
    this.groupId = '',
    this.groupName = '',
    this.districtId = '',
    this.districtName = '',
    this.stateId = '',
    this.stateName = '',
    this.groupType = '',
    this.status = 'active',
    bool? active,
  }) : active = active ?? (status == 'active');
}

class UserModel {
  String id;
  String username;
  String fullName;
  String role; // Administrator, District Incharge, Data Entry, Viewer
  String email;
  String status; // Active, Inactive

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.email,
    this.status = 'Active',
  });
}

class Village {
  String id;
  String name;
  String nameEnglish;
  String nameGujarati;
  String nameHindi;
  String districtId;
  String districtName;
  String status; // 'active' / 'inactive'
  bool active;

  Village({
    required this.id,
    String? name,
    this.nameEnglish = '',
    this.nameGujarati = '',
    this.nameHindi = '',
    this.districtId = '',
    this.districtName = '',
    this.status = 'active',
    bool? active,
  })  : name = name ?? (nameEnglish.isNotEmpty ? nameEnglish : 'Village #$id'),
        active = active ?? (status == 'active');
}


