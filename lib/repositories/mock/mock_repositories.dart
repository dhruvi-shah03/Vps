import '../../models/app_models.dart';
import '../interfaces/app_repositories.dart';

class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser = UserModel(
    id: 'usr_001',
    username: 'admin',
    fullName: 'Administrator User',
    role: 'Administrator',
    email: 'admin@vps.org',
    status: 'Active',
  );

  @override
  Future<bool> login(String username, String password) async {
    // Simple mock authentication check
    if (username == 'admin' && password == 'admin123') {
      _currentUser = UserModel(
        id: 'usr_001',
        username: 'admin',
        fullName: 'System Administrator',
        role: 'Administrator',
        email: 'admin@vps.org',
        status: 'Active',
      );
      return true;
    } else if (username.isNotEmpty && password.isNotEmpty) {
      _currentUser = UserModel(
        id: 'usr_demo',
        username: username,
        fullName: username.toUpperCase(),
        role: 'Data Entry',
        email: '$username@vps.org',
        status: 'Active',
      );
      return true;
    }
    return false;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _currentUser;
  }
}

class MockMahatmaRepository implements MahatmaRepository {
  final List<Mahatma> _items = [
    Mahatma(
      id: 'm_001',
      code: 'M001',
      letterNo: 'L-2026/01',
      nameEnglish: 'Mahatma Ananda Suri',
      nameGujarati: 'મહાત્મા આનંદ સૂરિ',
      nameHindi: 'महात्मा आनंद सूरि',
      samuday: 'Shri Tapagaccha Samuday',
      sevakName: 'Ramesh Patel',
      contactPerson: 'Ramesh Patel',
      contactNumber: '+91 98765 43210',
      thanaNo: 'T-101',
      selectedDate: DateTime(2026, 3, 15),
      districtIncharge: 'Rajesh Shah (Ahmedabad)',
      salutation: 'Acharya',
      active: true,
    ),
    Mahatma(
      id: 'm_002',
      code: 'M002',
      letterNo: 'L-2026/02',
      nameEnglish: 'Mahatma Vijay Ratna',
      nameGujarati: 'મહાત્મા વિજય રત્ન',
      nameHindi: 'महात्मा विजय रत्न',
      samuday: 'Shri Prem Samuday',
      sevakName: 'Suresh Kumar',
      contactNumber: '+91 98765 43211',
      thanaNo: 'T-102',
      selectedDate: DateTime(2026, 4, 10),
      districtIncharge: 'Mahesh Mehta (Gandhinagar)',
      salutation: 'Muni',
      active: true,
    ),
    Mahatma(
      id: 'm_003',
      code: 'M003',
      letterNo: 'L-2026/03',
      nameEnglish: 'Mahatma Hem Chandra',
      nameGujarati: 'મહાત્મા હેમ ચંદ્ર',
      nameHindi: 'महात्मा हेम चंद्र',
      samuday: 'Shri Ram Samuday',
      sevakName: 'Jiten Sharma',
      contactNumber: '+91 98765 43212',
      thanaNo: 'T-103',
      selectedDate: DateTime(2026, 5, 20),
      districtIncharge: 'Dinesh Joshi (Surat)',
      salutation: 'Acharya',
      active: true,
    ),
    Mahatma(
      id: 'm_004',
      code: 'M004',
      letterNo: 'L-2026/04',
      nameEnglish: 'Mahatma Bhadra Suri',
      nameGujarati: 'મહાત્મા ભદ્ર સૂરિ',
      nameHindi: 'महात्मा भद्र सूरि',
      samuday: 'Shri Tapagaccha Samuday',
      sevakName: 'Bhavik Desai',
      contactNumber: '+91 98765 43213',
      thanaNo: 'T-104',
      selectedDate: DateTime(2026, 6, 12),
      districtIncharge: 'Kirit Vora (Rajkot)',
      salutation: 'Shri',
      active: true,
    ),
    Mahatma(
      id: 'm_005',
      code: 'M005',
      letterNo: 'L-2026/05',
      nameEnglish: 'Mahatma Kirti Muni',
      nameGujarati: 'મહાત્મા કીર્તિ મુનિ',
      nameHindi: 'महात्मा कीर्ति मुनि',
      samuday: 'Shri Ocean Samuday',
      sevakName: 'Nitin Bhatt',
      contactNumber: '+91 98765 43214',
      thanaNo: 'T-105',
      selectedDate: DateTime(2026, 7, 18),
      districtIncharge: 'Sanjay Trivedi (Vadodara)',
      salutation: 'Muni',
      active: true,
    ),
    Mahatma(
      id: 'm_006',
      code: 'M006',
      letterNo: 'L-2026/06',
      nameEnglish: 'Mahatma Vidyanandji',
      nameGujarati: 'મહાત્મા વિદ્યાનંદજી',
      nameHindi: 'महात्मा विद्यानंदजी',
      samuday: 'Shri Shanti Samuday',
      sevakName: 'Ashok Parmar',
      contactNumber: '+91 98765 43215',
      thanaNo: 'T-106',
      selectedDate: DateTime(2026, 8, 05),
      districtIncharge: 'Pankaj Shah (Bhavnagar)',
      salutation: 'Acharya',
      active: true,
    ),
    Mahatma(
      id: 'm_007',
      code: 'M007',
      letterNo: 'L-2026/07',
      nameEnglish: 'Mahatma Rajendra Vijay',
      nameGujarati: 'મહાત્મા રાજેન્દ્ર વિજય',
      nameHindi: 'महात्मा राजेन्द्र विजय',
      samuday: 'Shri Prem Samuday',
      sevakName: 'Vikram Solanki',
      contactNumber: '+91 98765 43216',
      thanaNo: 'T-107',
      selectedDate: DateTime(2026, 8, 22),
      districtIncharge: 'Rajesh Shah (Ahmedabad)',
      salutation: 'Muni',
      active: true,
    ),
    Mahatma(
      id: 'm_008',
      code: 'M008',
      letterNo: 'L-2026/08',
      nameEnglish: 'Mahatma Siddharth Suri',
      nameGujarati: 'મહાત્મા સિદ્ધાર્થ સૂરિ',
      nameHindi: 'महात्मा सिद्धार्थ सूरि',
      samuday: 'Shri Tapagaccha Samuday',
      sevakName: 'Hitesh Patel',
      contactNumber: '+91 98765 43217',
      thanaNo: 'T-108',
      selectedDate: DateTime(2026, 9, 01),
      districtIncharge: 'Mahesh Mehta (Gandhinagar)',
      salutation: 'Acharya',
      active: true,
    ),
    Mahatma(
      id: 'm_009',
      code: 'M009',
      letterNo: 'L-2026/09',
      nameEnglish: 'Mahatma Shanti Muni',
      nameGujarati: 'મહાત્મા શાંતિ મુનિ',
      nameHindi: 'महात्मा शांति मुनि',
      samuday: 'Shri Shanti Samuday',
      sevakName: 'Manish Rathod',
      contactNumber: '+91 98765 43218',
      thanaNo: 'T-109',
      selectedDate: DateTime(2026, 9, 10),
      districtIncharge: 'Dinesh Joshi (Surat)',
      salutation: 'Muni',
      active: false,
    ),
    Mahatma(
      id: 'm_010',
      code: 'M010',
      letterNo: 'L-2026/10',
      nameEnglish: 'Mahatma Devendra Ratna',
      nameGujarati: 'મહાત્મા દેવેન્દ્ર રત્ન',
      nameHindi: 'महात्मा देवेन्द्र रत्न',
      samuday: 'Shri Ram Samuday',
      sevakName: 'Jayesh Dave',
      contactNumber: '+91 98765 43219',
      thanaNo: 'T-110',
      selectedDate: DateTime(2026, 9, 14),
      districtIncharge: 'Kirit Vora (Rajkot)',
      salutation: 'Acharya',
      active: true,
    ),
  ];

  @override
  Future<List<Mahatma>> getMahatmas() async => List.from(_items);

  @override
  Future<Mahatma?> getMahatmaById(String id) async {
    try {
      return _items.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addMahatma(Mahatma mahatma) async {
    _items.insert(0, mahatma);
  }

  @override
  Future<void> updateMahatma(Mahatma mahatma) async {
    final index = _items.indexWhere((element) => element.id == mahatma.id);
    if (index != -1) {
      _items[index] = mahatma;
    }
  }

  @override
  Future<void> deleteMahatma(String id) async {
    _items.removeWhere((element) => element.id == id);
  }
}

class MockViharRepository implements ViharRepository {
  final List<Vihar> _items = [
    Vihar(
      id: 'v_001',
      mahatmaId: 'm_001',
      mahatmaName: 'Mahatma Ananda Suri',
      startLocation: 'Ahmedabad Ashram',
      endLocation: 'Gandhinagar Temple',
      startDate: DateTime(2026, 9, 14),
      endDate: DateTime(2026, 9, 18),
      status: 'In Progress',
      notes: 'Morning departure at 5:30 AM',
    ),
    Vihar(
      id: 'v_002',
      mahatmaId: 'm_002',
      mahatmaName: 'Mahatma Vijay Ratna',
      startLocation: 'Gandhinagar Sector 21',
      endLocation: 'Mehsana Dham',
      startDate: DateTime(2026, 9, 20),
      endDate: DateTime(2026, 9, 25),
      status: 'Planned',
      notes: 'Halt at Kalol midpoint',
    ),
    Vihar(
      id: 'v_003',
      mahatmaId: 'm_003',
      mahatmaName: 'Mahatma Hem Chandra',
      startLocation: 'Surat City Center',
      endLocation: 'Navsari Complex',
      startDate: DateTime(2026, 9, 10),
      endDate: DateTime(2026, 9, 13),
      status: 'Completed',
      notes: 'Smooth journey via highway route',
    ),
    Vihar(
      id: 'v_004',
      mahatmaId: 'm_004',
      mahatmaName: 'Mahatma Bhadra Suri',
      startLocation: 'Rajkot Main Hall',
      endLocation: 'Morbi Bhavan',
      startDate: DateTime(2026, 9, 22),
      endDate: DateTime(2026, 9, 26),
      status: 'Planned',
      notes: 'Escort team arranged',
    ),
    Vihar(
      id: 'v_005',
      mahatmaId: 'm_005',
      mahatmaName: 'Mahatma Kirti Muni',
      startLocation: 'Vadodara Station',
      endLocation: 'Anand Ashram',
      startDate: DateTime(2026, 9, 01),
      endDate: DateTime(2026, 9, 05),
      status: 'Completed',
      notes: 'Completed ahead of schedule',
    ),
    Vihar(
      id: 'v_006',
      mahatmaId: 'm_006',
      mahatmaName: 'Mahatma Vidyanandji',
      startLocation: 'Bhavnagar Port Road',
      endLocation: 'Palitana Hill Foot',
      startDate: DateTime(2026, 9, 28),
      endDate: DateTime(2026, 10, 02),
      status: 'Planned',
      notes: 'Special pilgrimage group',
    ),
    Vihar(
      id: 'v_007',
      mahatmaId: 'm_007',
      mahatmaName: 'Mahatma Rajendra Vijay',
      startLocation: 'Ahmedabad Paldi',
      endLocation: 'Sanand Centre',
      startDate: DateTime(2026, 9, 16),
      endDate: DateTime(2026, 9, 19),
      status: 'In Progress',
      notes: 'Rest stops every 10 km',
    ),
    Vihar(
      id: 'v_008',
      mahatmaId: 'm_008',
      mahatmaName: 'Mahatma Siddharth Suri',
      startLocation: 'Gandhinagar Sector 1',
      endLocation: 'Mansu Bhavan',
      startDate: DateTime(2026, 10, 05),
      endDate: DateTime(2026, 10, 10),
      status: 'Planned',
      notes: 'Arrangements confirmed with district team',
    ),
    Vihar(
      id: 'v_009',
      mahatmaId: 'm_009',
      mahatmaName: 'Mahatma Shanti Muni',
      startLocation: 'Surat Ring Road',
      endLocation: 'Kamrej Circle',
      startDate: DateTime(2026, 8, 15),
      endDate: DateTime(2026, 8, 18),
      status: 'Completed',
      notes: 'Annual monsoon stay',
    ),
    Vihar(
      id: 'v_010',
      mahatmaId: 'm_010',
      mahatmaName: 'Mahatma Devendra Ratna',
      startLocation: 'Rajkot Gondal Road',
      endLocation: 'Shapur Village',
      startDate: DateTime(2026, 10, 15),
      endDate: DateTime(2026, 10, 20),
      status: 'Planned',
      notes: 'Community welcome arranged',
    ),
  ];

  @override
  Future<List<Vihar>> getVihars() async => List.from(_items);

  @override
  Future<Vihar?> getViharById(String id) async {
    try {
      return _items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addVihar(Vihar vihar) async {
    _items.insert(0, vihar);
  }

  @override
  Future<void> updateVihar(Vihar vihar) async {
    final index = _items.indexWhere((e) => e.id == vihar.id);
    if (index != -1) {
      _items[index] = vihar;
    }
  }

  @override
  Future<void> deleteVihar(String id) async {
    _items.removeWhere((e) => e.id == id);
  }
}

class MockViharRouteRepository implements ViharRouteRepository {
  final List<ViharRoute> _items = [
    ViharRoute(
      id: 'vr_001',
      viharDate: DateTime(2026, 9, 14),
      fromLocation: 'Ahmedabad (Navrangpura)',
      toLocation: 'Gandhinagar (Sector 11)',
      district: 'Ahmedabad',
      districtInchargeInfo: 'Rajesh Shah (+91 98111 22334)',
      distanceKm: 28.5,
      status: 'Active',
    ),
    ViharRoute(
      id: 'vr_002',
      viharDate: DateTime(2026, 9, 16),
      fromLocation: 'Gandhinagar (Infocity)',
      toLocation: 'Mehsana (Highway Touch)',
      district: 'Gandhinagar',
      districtInchargeInfo: 'Mahesh Mehta (+91 98222 33445)',
      distanceKm: 54.0,
      status: 'Upcoming',
    ),
    ViharRoute(
      id: 'vr_003',
      viharDate: DateTime(2026, 9, 10),
      fromLocation: 'Surat (Adajan)',
      toLocation: 'Navsari (Station Road)',
      district: 'Surat',
      districtInchargeInfo: 'Dinesh Joshi (+91 98333 44556)',
      distanceKm: 32.0,
      status: 'Completed',
    ),
    ViharRoute(
      id: 'vr_004',
      viharDate: DateTime(2026, 9, 22),
      fromLocation: 'Rajkot (Kalawad Road)',
      toLocation: 'Morbi (Bypass)',
      district: 'Rajkot',
      districtInchargeInfo: 'Kirit Vora (+91 98444 55667)',
      distanceKm: 65.0,
      status: 'Upcoming',
    ),
    ViharRoute(
      id: 'vr_005',
      viharDate: DateTime(2026, 9, 02),
      fromLocation: 'Vadodara (Alkapuri)',
      toLocation: 'Anand (Milk City)',
      district: 'Vadodara',
      districtInchargeInfo: 'Sanjay Trivedi (+91 98555 66778)',
      distanceKm: 42.0,
      status: 'Completed',
    ),
    ViharRoute(
      id: 'vr_006',
      viharDate: DateTime(2026, 9, 28),
      fromLocation: 'Bhavnagar (Waghawadi)',
      toLocation: 'Songadh (Ghar)',
      district: 'Bhavnagar',
      districtInchargeInfo: 'Pankaj Shah (+91 98666 77889)',
      distanceKm: 25.0,
      status: 'Upcoming',
    ),
    ViharRoute(
      id: 'vr_007',
      viharDate: DateTime(2026, 9, 18),
      fromLocation: 'Ahmedabad (Satellite)',
      toLocation: 'Sanand (GIDC Circle)',
      district: 'Ahmedabad',
      districtInchargeInfo: 'Rajesh Shah (+91 98111 22334)',
      distanceKm: 22.0,
      status: 'Upcoming',
    ),
    ViharRoute(
      id: 'vr_008',
      viharDate: DateTime(2026, 10, 05),
      fromLocation: 'Gandhinagar (Sector 28)',
      toLocation: 'Mansa (Town)',
      district: 'Gandhinagar',
      districtInchargeInfo: 'Mahesh Mehta (+91 98222 33445)',
      distanceKm: 30.0,
      status: 'Upcoming',
    ),
    ViharRoute(
      id: 'vr_009',
      viharDate: DateTime(2026, 8, 12),
      fromLocation: 'Surat (Varachha)',
      toLocation: 'Kamrej (Expressway)',
      district: 'Surat',
      districtInchargeInfo: 'Dinesh Joshi (+91 98333 44556)',
      distanceKm: 18.0,
      status: 'Completed',
    ),
    ViharRoute(
      id: 'vr_010',
      viharDate: DateTime(2026, 10, 12),
      fromLocation: 'Rajkot (150ft Ring Rd)',
      toLocation: 'Gondal (Bridge)',
      district: 'Rajkot',
      districtInchargeInfo: 'Kirit Vora (+91 98444 55667)',
      distanceKm: 38.0,
      status: 'Upcoming',
    ),
  ];

  @override
  Future<List<ViharRoute>> getViharRoutes() async => List.from(_items);

  @override
  Future<ViharRoute?> getViharRouteById(String id) async {
    try {
      return _items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addViharRoute(ViharRoute route) async {
    _items.insert(0, route);
  }

  @override
  Future<void> updateViharRoute(ViharRoute route) async {
    final index = _items.indexWhere((e) => e.id == route.id);
    if (index != -1) {
      _items[index] = route;
    }
  }

  @override
  Future<void> deleteViharRoute(String id) async {
    _items.removeWhere((e) => e.id == id);
  }
}

class MockSamudayRepository implements SamudayRepository {
  final List<Samuday> _items = [
    Samuday(id: 's_001', name: 'Shri Tapagaccha Samuday', code: 'TAP01', active: true),
    Samuday(id: 's_002', name: 'Shri Prem Samuday', code: 'PRM02', active: true),
    Samuday(id: 's_003', name: 'Shri Ram Samuday', code: 'RAM03', active: true),
    Samuday(id: 's_004', name: 'Shri Ocean Samuday', code: 'OCN04', active: true),
    Samuday(id: 's_005', name: 'Shri Shanti Samuday', code: 'SNT05', active: true),
  ];

  @override
  Future<List<Samuday>> getSamudays() async => List.from(_items);

  @override
  Future<void> addSamuday(Samuday item) async {
    _items.insert(0, item);
  }

  @override
  Future<void> updateSamuday(Samuday item) async {
    final i = _items.indexWhere((e) => e.id == item.id);
    if (i != -1) _items[i] = item;
  }

  @override
  Future<void> deleteSamuday(String id) async {
    _items.removeWhere((e) => e.id == id);
  }
}

class MockDistrictRepository implements DistrictRepository {
  final List<District> _items = [
    District(id: 'd_001', name: 'Ahmedabad', state: 'Gujarat', active: true),
    District(id: 'd_002', name: 'Gandhinagar', state: 'Gujarat', active: true),
    District(id: 'd_003', name: 'Surat', state: 'Gujarat', active: true),
    District(id: 'd_004', name: 'Rajkot', state: 'Gujarat', active: true),
    District(id: 'd_005', name: 'Vadodara', state: 'Gujarat', active: true),
    District(id: 'd_006', name: 'Bhavnagar', state: 'Gujarat', active: true),
    District(id: 'd_007', name: 'Junagadh', state: 'Gujarat', active: true),
    District(id: 'd_008', name: 'Jamnagar', state: 'Gujarat', active: true),
  ];

  @override
  Future<List<District>> getDistricts() async => List.from(_items);

  @override
  Future<void> addDistrict(District item) async {
    _items.insert(0, item);
  }

  @override
  Future<void> updateDistrict(District item) async {
    final i = _items.indexWhere((e) => e.id == item.id);
    if (i != -1) _items[i] = item;
  }

  @override
  Future<void> deleteDistrict(String id) async {
    _items.removeWhere((e) => e.id == id);
  }
}

class MockDistrictInchargeRepository implements DistrictInchargeRepository {
  final List<DistrictIncharge> _items = [
    DistrictIncharge(id: 'di_001', name: 'Rajesh Shah', district: 'Ahmedabad', contactNumber: '+91 98111 22334', email: 'rajesh.ahmedabad@vps.org'),
    DistrictIncharge(id: 'di_002', name: 'Mahesh Mehta', district: 'Gandhinagar', contactNumber: '+91 98222 33445', email: 'mahesh.gandhinagar@vps.org'),
    DistrictIncharge(id: 'di_003', name: 'Dinesh Joshi', district: 'Surat', contactNumber: '+91 98333 44556', email: 'dinesh.surat@vps.org'),
    DistrictIncharge(id: 'di_004', name: 'Kirit Vora', district: 'Rajkot', contactNumber: '+91 98444 55667', email: 'kirit.rajkot@vps.org'),
    DistrictIncharge(id: 'di_005', name: 'Sanjay Trivedi', district: 'Vadodara', contactNumber: '+91 98555 66778', email: 'sanjay.vadodara@vps.org'),
    DistrictIncharge(id: 'di_006', name: 'Pankaj Shah', district: 'Bhavnagar', contactNumber: '+91 98666 77889', email: 'pankaj.bhavnagar@vps.org'),
    DistrictIncharge(id: 'di_007', name: 'Anil Desai', district: 'Junagadh', contactNumber: '+91 98777 88990', email: 'anil.junagadh@vps.org'),
    DistrictIncharge(id: 'di_008', name: 'Deepak Patel', district: 'Jamnagar', contactNumber: '+91 98888 99001', email: 'deepak.jamnagar@vps.org'),
  ];

  @override
  Future<List<DistrictIncharge>> getDistrictIncharges() async => List.from(_items);

  @override
  Future<void> addDistrictIncharge(DistrictIncharge item) async {
    _items.insert(0, item);
  }

  @override
  Future<void> updateDistrictIncharge(DistrictIncharge item) async {
    final i = _items.indexWhere((e) => e.id == item.id);
    if (i != -1) _items[i] = item;
  }

  @override
  Future<void> deleteDistrictIncharge(String id) async {
    _items.removeWhere((e) => e.id == id);
  }
}

class MockStateRepository implements StateRepository {
  final List<StateModel> _items = [
    StateModel(id: 'st_001', name: 'Gujarat', code: 'GJ', country: 'India', active: true),
    StateModel(id: 'st_002', name: 'Rajasthan', code: 'RJ', country: 'India', active: true),
    StateModel(id: 'st_003', name: 'Maharashtra', code: 'MH', country: 'India', active: true),
    StateModel(id: 'st_004', name: 'Madhya Pradesh', code: 'MP', country: 'India', active: true),
    StateModel(id: 'st_005', name: 'Delhi', code: 'DL', country: 'India', active: true),
  ];

  @override
  Future<List<StateModel>> getStates() async => List.from(_items);

  @override
  Future<void> addState(StateModel item) async {
    _items.insert(0, item);
  }

  @override
  Future<void> updateState(StateModel item) async {
    final i = _items.indexWhere((e) => e.id == item.id);
    if (i != -1) _items[i] = item;
  }

  @override
  Future<void> deleteState(String id) async {
    _items.removeWhere((e) => e.id == id);
  }
}

class MockSalutationRepository implements SalutationRepository {
  final List<Salutation> _items = [
    Salutation(id: 'sal_001', title: 'Shri', active: true),
    Salutation(id: 'sal_002', title: 'Smt.', active: true),
    Salutation(id: 'sal_003', title: 'Dr.', active: true),
    Salutation(id: 'sal_004', title: 'Acharya', active: true),
    Salutation(id: 'sal_005', title: 'Muni', active: true),
  ];

  @override
  Future<List<Salutation>> getSalutations() async => List.from(_items);

  @override
  Future<void> addSalutation(Salutation item) async {
    _items.insert(0, item);
  }

  @override
  Future<void> updateSalutation(Salutation item) async {
    final i = _items.indexWhere((e) => e.id == item.id);
    if (i != -1) _items[i] = item;
  }

  @override
  Future<void> deleteSalutation(String id) async {
    _items.removeWhere((e) => e.id == id);
  }
}

class MockUserRepository implements UserRepository {
  final List<UserModel> _items = [
    UserModel(id: 'usr_001', username: 'admin', fullName: 'System Administrator', role: 'Administrator', email: 'admin@vps.org', status: 'Active'),
    UserModel(id: 'usr_002', username: 'rajesh_inch', fullName: 'Rajesh Shah', role: 'District Incharge', email: 'rajesh@vps.org', status: 'Active'),
    UserModel(id: 'usr_003', username: 'entry_user1', fullName: 'Priya Sharma', role: 'Data Entry', email: 'priya@vps.org', status: 'Active'),
    UserModel(id: 'usr_004', username: 'viewer_user', fullName: 'Amit Verma', role: 'Viewer', email: 'amit@vps.org', status: 'Inactive'),
    UserModel(id: 'usr_005', username: 'entry_user2', fullName: 'Kavita Patel', role: 'Data Entry', email: 'kavita@vps.org', status: 'Active'),
  ];

  @override
  Future<List<UserModel>> getUsers() async => List.from(_items);

  @override
  Future<void> addUser(UserModel user) async {
    _items.insert(0, user);
  }

  @override
  Future<void> updateUser(UserModel user) async {
    final i = _items.indexWhere((e) => e.id == user.id);
    if (i != -1) _items[i] = user;
  }

  @override
  Future<void> deleteUser(String id) async {
    _items.removeWhere((e) => e.id == id);
  }
}

class MockVillageRepository implements VillageRepository {
  final List<Village> _items = [
    // Ahmedabad
    Village(id: 'v_001', nameEnglish: 'Navrangpura', nameGujarati: 'નવરંગપુરા', nameHindi: 'नवरंगपुरा', districtId: 'd_001', districtName: 'Ahmedabad', status: 'active', active: true),
    Village(id: 'v_002', nameEnglish: 'Paldi', nameGujarati: 'પાલડી', nameHindi: 'पालडी', districtId: 'd_001', districtName: 'Ahmedabad', status: 'active', active: true),
    Village(id: 'v_003', nameEnglish: 'Maninagar', nameGujarati: 'મણિનગર', nameHindi: 'मणिनगर', districtId: 'd_001', districtName: 'Ahmedabad', status: 'active', active: true),
    Village(id: 'v_004', nameEnglish: 'Bopal', nameGujarati: 'બોપલ', nameHindi: 'बोपल', districtId: 'd_001', districtName: 'Ahmedabad', status: 'active', active: true),
    Village(id: 'v_005', nameEnglish: 'Vastrapur', nameGujarati: 'વસ્ત્રાપુર', nameHindi: 'वस्त्रापुर', districtId: 'd_001', districtName: 'Ahmedabad', status: 'active', active: true),
    Village(id: 'v_006', nameEnglish: 'Sanand', nameGujarati: 'સાણંદ', nameHindi: 'साणंद', districtId: 'd_001', districtName: 'Ahmedabad', status: 'active', active: true),
    Village(id: 'v_007', nameEnglish: 'Dholka', nameGujarati: 'ધોળકા', nameHindi: 'धोलका', districtId: 'd_001', districtName: 'Ahmedabad', status: 'active', active: true),
    Village(id: 'v_008', nameEnglish: 'Viramgam', nameGujarati: 'વિરમગામ', nameHindi: 'वीरमगाम', districtId: 'd_001', districtName: 'Ahmedabad', status: 'active', active: true),
    // Gandhinagar
    Village(id: 'v_009', nameEnglish: 'Infocity', nameGujarati: 'ઇન્ફોસિટી', nameHindi: 'इन्फोसिटी', districtId: 'd_002', districtName: 'Gandhinagar', status: 'active', active: true),
    Village(id: 'v_010', nameEnglish: 'Sector 11', nameGujarati: 'સેક્ટર ૧૧', nameHindi: 'सेक्टर 11', districtId: 'd_002', districtName: 'Gandhinagar', status: 'active', active: true),
    Village(id: 'v_011', nameEnglish: 'Kalol', nameGujarati: 'કલોલ', nameHindi: 'कलोल', districtId: 'd_002', districtName: 'Gandhinagar', status: 'active', active: true),
    Village(id: 'v_012', nameEnglish: 'Mansa', nameGujarati: 'માણસા', nameHindi: 'मानसा', districtId: 'd_002', districtName: 'Gandhinagar', status: 'active', active: true),
    Village(id: 'v_013', nameEnglish: 'Dehgam', nameGujarati: 'દહેગામ', nameHindi: 'दहेगाम', districtId: 'd_002', districtName: 'Gandhinagar', status: 'active', active: true),
    // Surat
    Village(id: 'v_014', nameEnglish: 'Adajan', nameGujarati: 'અડાજણ', nameHindi: 'अडाजण', districtId: 'd_003', districtName: 'Surat', status: 'active', active: true),
    Village(id: 'v_015', nameEnglish: 'Katargam', nameGujarati: 'કતારગામ', nameHindi: 'कतारगाम', districtId: 'd_003', districtName: 'Surat', status: 'active', active: true),
    Village(id: 'v_016', nameEnglish: 'Varachha', nameGujarati: 'વરાછા', nameHindi: 'वराछा', districtId: 'd_003', districtName: 'Surat', status: 'active', active: true),
    Village(id: 'v_017', nameEnglish: 'Bardoli', nameGujarati: 'બારડોલી', nameHindi: 'बारडोली', districtId: 'd_003', districtName: 'Surat', status: 'active', active: true),
    Village(id: 'v_018', nameEnglish: 'Kamrej', nameGujarati: 'કામરેજ', nameHindi: 'कामरेज', districtId: 'd_003', districtName: 'Surat', status: 'active', active: true),
    // Rajkot
    Village(id: 'v_019', nameEnglish: 'Kalawad Road', nameGujarati: 'કાલાવાડ રોડ', nameHindi: 'कालावड रोड', districtId: 'd_004', districtName: 'Rajkot', status: 'active', active: true),
    Village(id: 'v_020', nameEnglish: 'Gondal', nameGujarati: 'ગોંડલ', nameHindi: 'गोंडल', districtId: 'd_004', districtName: 'Rajkot', status: 'active', active: true),
    Village(id: 'v_021', nameEnglish: 'Jetpur', nameGujarati: 'જેતપુર', nameHindi: 'જેતપુર', districtId: 'd_004', districtName: 'Rajkot', status: 'active', active: true),
    Village(id: 'v_022', nameEnglish: 'Dhoraji', nameGujarati: 'ધોરાજી', nameHindi: 'धोराजी', districtId: 'd_004', districtName: 'Rajkot', status: 'active', active: true),
    Village(id: 'v_023', nameEnglish: 'Upleta', nameGujarati: 'ઉપલેટા', nameHindi: 'उपलेटा', districtId: 'd_004', districtName: 'Rajkot', status: 'active', active: true),
    // Vadodara
    Village(id: 'v_024', nameEnglish: 'Alkapuri', nameGujarati: 'અલકાપુરી', nameHindi: 'अलकापुरी', districtId: 'd_005', districtName: 'Vadodara', status: 'active', active: true),
    Village(id: 'v_025', nameEnglish: 'Manjalpur', nameGujarati: 'માંજલપુર', nameHindi: 'मांजलपुर', districtId: 'd_005', districtName: 'Vadodara', status: 'active', active: true),
    Village(id: 'v_026', nameEnglish: 'Padra', nameGujarati: 'પાદરા', nameHindi: 'पादरा', districtId: 'd_005', districtName: 'Vadodara', status: 'active', active: true),
    Village(id: 'v_027', nameEnglish: 'Karjan', nameGujarati: 'કરજણ', nameHindi: 'करजण', districtId: 'd_005', districtName: 'Vadodara', status: 'active', active: true),
    Village(id: 'v_028', nameEnglish: 'Dabhoi', nameGujarati: 'ડભોઇ', nameHindi: 'डभोई', districtId: 'd_005', districtName: 'Vadodara', status: 'active', active: true),
    // Bhavnagar
    Village(id: 'v_029', nameEnglish: 'Waghawadi', nameGujarati: 'વાઘાવાડી', nameHindi: 'वाघावाड़ी', districtId: 'd_006', districtName: 'Bhavnagar', status: 'active', active: true),
    Village(id: 'v_030', nameEnglish: 'Palitana', nameGujarati: 'પાલીતાણા', nameHindi: 'पालीताना', districtId: 'd_006', districtName: 'Bhavnagar', status: 'active', active: true),
    Village(id: 'v_031', nameEnglish: 'Songadh', nameGujarati: 'સોનગઢ', nameHindi: 'सोनगढ़', districtId: 'd_006', districtName: 'Bhavnagar', status: 'active', active: true),
    Village(id: 'v_032', nameEnglish: 'Sihor', nameGujarati: 'શિહોર', nameHindi: 'शिहोर', districtId: 'd_006', districtName: 'Bhavnagar', status: 'active', active: true),
    Village(id: 'v_033', nameEnglish: 'Mahuva', nameGujarati: 'મહુવા', nameHindi: 'महुवा', districtId: 'd_006', districtName: 'Bhavnagar', status: 'active', active: true),
    // Junagadh
    Village(id: 'v_034', nameEnglish: 'Keshod', nameGujarati: 'કેશોદ', nameHindi: 'केशोद', districtId: 'd_007', districtName: 'Junagadh', status: 'active', active: true),
    Village(id: 'v_035', nameEnglish: 'Mangrol', nameGujarati: 'માંગરોળ', nameHindi: 'मांगरोल', districtId: 'd_007', districtName: 'Junagadh', status: 'active', active: true),
    Village(id: 'v_036', nameEnglish: 'Visavadar', nameGujarati: 'વિસાવદર', nameHindi: 'विसावदर', districtId: 'd_007', districtName: 'Junagadh', status: 'active', active: true),
    // Jamnagar
    Village(id: 'v_037', nameEnglish: 'Dhrol', nameGujarati: 'ધ્રોલ', nameHindi: 'ध्रोल', districtId: 'd_008', districtName: 'Jamnagar', status: 'active', active: true),
    Village(id: 'v_038', nameEnglish: 'Lalpur', nameGujarati: 'લાલપુર', nameHindi: 'लालपुर', districtId: 'd_008', districtName: 'Jamnagar', status: 'active', active: true),
    Village(id: 'v_039', nameEnglish: 'Kalavad', nameGujarati: 'કાલાવાડ', nameHindi: 'कालावड', districtId: 'd_008', districtName: 'Jamnagar', status: 'active', active: true),
    Village(id: 'v_040', nameEnglish: 'Jamjodhpur', nameGujarati: 'જામજોધપુર', nameHindi: 'जामजोधपुर', districtId: 'd_008', districtName: 'Jamnagar', status: 'active', active: true),
  ];

  @override
  Future<List<Village>> getVillages() async => List.from(_items);

  @override
  Future<void> addVillage(Village item) async {
    _items.insert(0, item);
  }

  @override
  Future<void> updateVillage(Village item) async {
    final i = _items.indexWhere((e) => e.id == item.id);
    if (i != -1) _items[i] = item;
  }

  @override
  Future<void> deleteVillage(String id) async {
    _items.removeWhere((e) => e.id == id);
  }
}

