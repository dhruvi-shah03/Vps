import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../models/app_models.dart';
import '../../services/odoo_client.dart';
import '../interfaces/app_repositories.dart';


class OdooAuthRepository implements AuthRepository {
  final OdooClient client;

  OdooAuthRepository(this.client);

  @override
  Future<bool> login(String username, String password) async {
    final result = await client.authenticate(login: username, password: password);
    return result['uid'] != null && result['uid'] != false;
  }

  @override
  Future<void> logout() async {
    await client.logout();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    if (!client.isAuthenticated) return null;
    return UserModel(
      id: '${client.uid}',
      username: client.username ?? 'user',
      fullName: client.userFullName ?? client.username ?? 'VPS User',
      role: 'Administrator',
      email: '${client.username}@vps.arihantai.com',
      status: 'Active',
    );
  }
}

class OdooMahatmaRepository implements MahatmaRepository {
  final OdooClient client;

  OdooMahatmaRepository(this.client);

  @override
  Future<List<Mahatma>> getMahatmas() async {
    final records = await client.searchRead(
      model: 'ai.mahatma',
      fields: [
        'id',
        'code',
        'name_en',
        'name_gu',
        'name_hi',
        'samuday_id',
        'contact_person',
        'contact_number',
        'alternate_contact_number',
        'is_cancelled'
      ],
      order: 'id desc',
    );

    return records.map((r) {
      String samudayName = 'General';
      if (r['samuday_id'] is List && (r['samuday_id'] as List).length > 1) {
        samudayName = (r['samuday_id'] as List)[1].toString();
      }

      final contactP = r['contact_person']?.toString() ?? '';
      final contactN = r['contact_number']?.toString() ?? '';

      return Mahatma(
        id: '${r['id']}',
        code: r['code']?.toString() ?? '',
        letterNo: 'L-${r['id']}',
        nameEnglish: r['name_en']?.toString() ?? '',
        nameGujarati: r['name_gu']?.toString() ?? '',
        nameHindi: r['name_hi']?.toString() ?? '',
        samuday: samudayName,
        sevakName: contactP,
        contactPerson: contactP,
        contactNumber: contactN,
        thanaNo: '',
        selectedDate: DateTime.now(),
        districtIncharge: '',
        salutation: 'Shri',
        active: !(r['is_cancelled'] == true),
      );
    }).toList();
  }

  @override
  Future<Mahatma?> getMahatmaById(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return null;

    final records = await client.searchRead(
      model: 'ai.mahatma',
      domain: [
        ['id', '=', intId]
      ],
      fields: [
        'id',
        'code',
        'name_en',
        'name_gu',
        'name_hi',
        'samuday_id',
        'contact_person',
        'contact_number',
        'alternate_contact_number',
        'is_cancelled'
      ],
      limit: 1,
    );

    if (records.isEmpty) return null;
    final r = records.first;
    String samudayName = 'General';
    if (r['samuday_id'] is List && (r['samuday_id'] as List).length > 1) {
      samudayName = (r['samuday_id'] as List)[1].toString();
    }

    final contactP = r['contact_person']?.toString() ?? '';
    return Mahatma(
      id: '${r['id']}',
      code: r['code']?.toString() ?? '',
      letterNo: 'L-${r['id']}',
      nameEnglish: r['name_en']?.toString() ?? '',
      nameGujarati: r['name_gu']?.toString() ?? '',
      nameHindi: r['name_hi']?.toString() ?? '',
      samuday: samudayName,
      sevakName: contactP,
      contactPerson: contactP,
      contactNumber: r['contact_number']?.toString() ?? '',
      active: !(r['is_cancelled'] == true),
    );
  }

  @override
  Future<void> addMahatma(Mahatma mahatma) async {
    final values = <String, dynamic>{
      'code': mahatma.code.trim(),
      'name_en': mahatma.nameEnglish.trim(),
      'name_gu': mahatma.nameGujarati.trim(),
      'name_hi': mahatma.nameHindi.trim(),
      'contact_person': (mahatma.contactPerson.isNotEmpty ? mahatma.contactPerson : mahatma.sevakName).trim(),
      'contact_number': mahatma.contactNumber.trim(),
    };

    // If samuday is provided, resolve to ID if possible
    final sId = int.tryParse(mahatma.samuday);
    if (sId != null) {
      values['samuday_id'] = sId;
    } else if (mahatma.samuday.isNotEmpty) {
      final sRecords = await client.searchRead(
        model: 'ai.samuday',
        domain: [
          ['name', '=ilike', mahatma.samuday.trim()]
        ],
        fields: ['id'],
        limit: 1,
      );
      if (sRecords.isNotEmpty) {
        values['samuday_id'] = sRecords.first['id'];
      }
    }

    await client.create(model: 'ai.mahatma', values: values);
  }

  @override
  Future<void> updateMahatma(Mahatma mahatma) async {
    final intId = int.tryParse(mahatma.id);
    if (intId == null) return;

    final values = <String, dynamic>{
      'code': mahatma.code.trim(),
      'name_en': mahatma.nameEnglish.trim(),
      'name_gu': mahatma.nameGujarati.trim(),
      'name_hi': mahatma.nameHindi.trim(),
      'contact_person': (mahatma.contactPerson.isNotEmpty ? mahatma.contactPerson : mahatma.sevakName).trim(),
      'contact_number': mahatma.contactNumber.trim(),
    };

    final sId = int.tryParse(mahatma.samuday);
    if (sId != null) {
      values['samuday_id'] = sId;
    } else if (mahatma.samuday.isNotEmpty) {
      final sRecords = await client.searchRead(
        model: 'ai.samuday',
        domain: [
          ['name', '=ilike', mahatma.samuday.trim()]
        ],
        fields: ['id'],
        limit: 1,
      );
      if (sRecords.isNotEmpty) {
        values['samuday_id'] = sRecords.first['id'];
      }
    }

    await client.write(model: 'ai.mahatma', id: intId, values: values);
  }

  @override
  Future<void> deleteMahatma(String id) async {
    final intId = int.tryParse(id);
    if (intId != null) {
      // Soft-delete or unlink
      try {
        await client.write(model: 'ai.mahatma', id: intId, values: {'is_cancelled': true});
      } catch (_) {
        await client.unlink(model: 'ai.mahatma', id: intId);
      }
    }
  }
}

Future<int?> _findOrCreateVillage(OdooClient client, String locName, [String? districtName]) async {
  final cleanName = locName.trim();
  if (cleanName.isEmpty) return null;

  try {
    // 1. Search by exact or ilike name_en
    final search1 = await client.searchRead(
      model: 'ai.village',
      domain: [
        ['name_en', '=ilike', cleanName]
      ],
      fields: ['id', 'name_en'],
      limit: 1,
    );
    if (search1.isNotEmpty) {
      return search1.first['id'] as int;
    }

    // 2. Search by contains in name
    final search2 = await client.searchRead(
      model: 'ai.village',
      domain: [
        ['name', 'ilike', cleanName]
      ],
      fields: ['id', 'name'],
      limit: 1,
    );
    if (search2.isNotEmpty) {
      return search2.first['id'] as int;
    }

    // 3. Find district ID if possible
    int? distId;
    if (districtName != null && districtName.isNotEmpty) {
      final dSearch = await client.searchRead(
        model: 'ai.district',
        domain: [
          ['name_en', '=ilike', districtName.trim()]
        ],
        fields: ['id'],
        limit: 1,
      );
      if (dSearch.isNotEmpty) {
        distId = dSearch.first['id'] as int;
      }
    }

    if (distId == null) {
      final firstDist = await client.searchRead(
        model: 'ai.district',
        fields: ['id'],
        limit: 1,
      );
      if (firstDist.isNotEmpty) {
        distId = firstDist.first['id'] as int;
      }
    }

    if (distId != null) {
      return await client.create(
        model: 'ai.village',
        values: {
          'name_en': cleanName,
          'name_gu': cleanName,
          'name_hi': cleanName,
          'district_id': distId,
          'status': 'active',
        },
      );
    }
  } catch (_) {
    // Graceful fallback
  }
  return null;
}

class OdooViharRepository implements ViharRepository {
  final OdooClient client;

  OdooViharRepository(this.client);

  @override
  Future<List<Vihar>> getVihars() async {
    List<Map<String, dynamic>> records = [];
    try {
      records = await client.searchRead(
        model: 'ai.add.vihar',
        fields: [
          'id',
          'code',
          'letter_no',
          'ms_name_en',
          'ms_name_gu',
          'ms_name_hi',
          'samuday_id',
          'sevak_name',
          'contact_number',
          'thana_no',
          'selected_date',
          'vihar_id',
          'is_active',
          'is_cancelled',
        ],
        order: 'id desc',
        context: {'active_test': false},
      );
    } catch (e) {
      debugPrint('[OdooViharRepository] primary getVihars failed: $e, trying safe fields...');
      try {
        records = await client.searchRead(
          model: 'ai.add.vihar',
          fields: [
            'id',
            'code',
            'ms_name_en',
            'letter_no',
            'thana_no',
            'sevak_name',
            'contact_number',
            'vihar_id',
            'is_active',
            'is_cancelled',
            'selected_date',
          ],
          order: 'id desc',
          context: {'active_test': false},
        );
      } catch (e2) {
        debugPrint('[OdooViharRepository] minimal getVihars failed: $e2');
        rethrow;
      }
    }

    // Fetch related routes for these vihars with active_test: false so draft/inactive routes are also retrieved
    List<Map<String, dynamic>> allRoutes = [];
    try {
      allRoutes = await client.searchRead(
        model: 'ai.vihar.route',
        fields: [
          'id',
          'vihar_id',
          'vihar_date_time',
          'from_location_id',
          'to_location_id',
          'name_en',
          'name_gu',
          'name_hi',
          'district_id',
          'district_incharge_info_en',
          'is_active',
          'active',
        ],
        order: 'vihar_date_time asc',
        context: {'active_test': false},
      );
    } catch (e) {
      debugPrint('[OdooViharRepository] allRoutes failed: $e');
    }

    final Map<int, ViharRoute> routesById = {};
    final Map<int, List<ViharRoute>> viharRoutesMap = {};
    for (var r in allRoutes) {
      final rId = r['id'] is int ? r['id'] as int : int.tryParse('${r['id']}');

      int? vId;
      String vName = '';
      if (r['vihar_id'] is List && (r['vihar_id'] as List).isNotEmpty) {
        vId = (r['vihar_id'] as List)[0] as int;
        if ((r['vihar_id'] as List).length > 1) {
          vName = (r['vihar_id'] as List)[1].toString();
        }
      } else if (r['vihar_id'] is int) {
        vId = r['vihar_id'] as int;
      } else if (r['vihar_id'] != null) {
        vId = int.tryParse('${r['vihar_id']}');
      }

      String fromLoc = '';
      if (r['from_location_id'] is List && (r['from_location_id'] as List).length > 1) {
        fromLoc = (r['from_location_id'] as List)[1].toString();
        if (fromLoc.contains(' | ')) {
          fromLoc = fromLoc.split(' | ').first.trim();
        }
      }

      String toLoc = '';
      if (r['to_location_id'] is List && (r['to_location_id'] as List).length > 1) {
        toLoc = (r['to_location_id'] as List)[1].toString();
        if (toLoc.contains(' | ')) {
          toLoc = toLoc.split(' | ').first.trim();
        }
      }

      if (fromLoc.isEmpty || toLoc.isEmpty) {
        final rawName = r['name_en'] ?? r['name_gu'] ?? r['name_hi'];
        if (rawName != null && rawName.toString().isNotEmpty) {
          final str = rawName.toString();
          if (str.toLowerCase().contains(' to ')) {
            final parts = str.split(RegExp(r'\s+to\s+', caseSensitive: false));
            if (parts.isNotEmpty && fromLoc.isEmpty) fromLoc = parts.first.trim();
            if (parts.length > 1 && toLoc.isEmpty) toLoc = parts.last.trim();
          } else if (fromLoc.isEmpty && toLoc.isEmpty) {
            fromLoc = str.trim();
            toLoc = str.trim();
          }
        }
      }

      String dist = '';
      if (r['district_id'] is List && (r['district_id'] as List).length > 1) {
        dist = (r['district_id'] as List)[1].toString();
      }
      if (dist.isEmpty && r['from_location_id'] is List && (r['from_location_id'] as List).length > 1) {
        final locFull = (r['from_location_id'] as List)[1].toString();
        if (locFull.contains(' | ')) {
          dist = locFull.split(' | ').last.trim();
        }
      }
      if (dist.isEmpty && r['to_location_id'] is List && (r['to_location_id'] as List).length > 1) {
        final locFull = (r['to_location_id'] as List)[1].toString();
        if (locFull.contains(' | ')) {
          dist = locFull.split(' | ').last.trim();
        }
      }
      if (dist.isEmpty) dist = 'Gujarat';

      String incharge = r['district_incharge_info_en']?.toString() ?? '';

      final routeObj = ViharRoute(
        id: '${r['id']}',
        viharId: vId != null ? '$vId' : '',
        viharName: vName,
        viharDate: DateTime.tryParse(r['vihar_date_time']?.toString() ?? '') ?? DateTime.now(),
        fromLocation: fromLoc,
        toLocation: toLoc,
        district: dist,
        districtInchargeInfo: incharge,
        status: (r['is_active'] == true || r['active'] == true) ? 'Active' : 'Upcoming',
      );

      if (rId != null) {
        routesById[rId] = routeObj;
      }
      if (vId != null) {
        viharRoutesMap.putIfAbsent(vId, () => []).add(routeObj);
      }
    }

    return records.map((r) {
      final int vId = r['id'] as int;
      String mahatmaName = r['ms_name_en']?.toString() ?? 'Mahatma';
      String mahatmaId = '1';
      if (r['code'] is List && (r['code'] as List).isNotEmpty) {
        mahatmaId = '${(r['code'] as List)[0]}';
        if (mahatmaName.isEmpty && (r['code'] as List).length > 1) {
          mahatmaName = (r['code'] as List)[1].toString();
        }
      }

      // First check Many2one mapping
      final List<ViharRoute> routesForThis = List.from(viharRoutesMap[vId] ?? []);

      // Second check One2many route ID list on the vihar record
      if (r['vihar_id'] is List) {
        for (var rid in (r['vihar_id'] as List)) {
          final intRid = rid is int ? rid : int.tryParse('$rid');
          if (intRid != null && routesById.containsKey(intRid)) {
            final routeFromId = routesById[intRid]!;
            if (!routesForThis.any((existing) => existing.id == routeFromId.id)) {
              routesForThis.add(routeFromId);
            }
          }
        }
      }

      routesForThis.sort((a, b) => a.viharDate.compareTo(b.viharDate));

      String startLoc = routesForThis.isNotEmpty ? routesForThis.first.fromLocation : '';
      String endLoc = routesForThis.isNotEmpty ? routesForThis.last.toLocation : '';

      DateTime sDate = DateTime.now();
      if (r['selected_date'] != null && r['selected_date'] != false) {
        sDate = DateTime.tryParse(r['selected_date'].toString()) ?? DateTime.now();
      } else if (routesForThis.isNotEmpty) {
        sDate = routesForThis.first.viharDate;
      }

      String statusStr = 'Planned';
      if (r['is_cancelled'] == true) {
        statusStr = 'Cancelled';
      } else if (r['is_active'] == true) {
        statusStr = 'Active';
      }

      return Vihar(
        id: '$vId',
        mahatmaId: mahatmaId,
        mahatmaName: mahatmaName,
        startLocation: startLoc,
        endLocation: endLoc,
        startDate: sDate,
        endDate: sDate.add(const Duration(hours: 4)),
        status: statusStr,
        notes: r['letter_no']?.toString() ?? '',
        letterNo: r['letter_no']?.toString() ?? '',
        salutation: 'Shri',
        thanaNo: r['thana_no']?.toString() ?? '',
        sevakName: r['sevak_name']?.toString() ?? '',
        contactNumber: r['contact_number']?.toString() ?? '',
        active: r['is_active'] == true,
        routes: routesForThis,
      );
    }).toList();
  }

  @override
  Future<Vihar?> getViharById(String id) async {
    final list = await getVihars();
    try {
      return list.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addVihar(Vihar vihar) async {
    final mId = int.tryParse(vihar.mahatmaId) ?? 1;

    // 1. Create ai.add.vihar
    final viharVals = <String, dynamic>{
      'code': mId,
      if (vihar.letterNo.isNotEmpty) 'letter_no': vihar.letterNo,
      if (vihar.thanaNo.isNotEmpty) 'thana_no': vihar.thanaNo,
      if (vihar.sevakName.isNotEmpty) 'sevak_name': vihar.sevakName,
      if (vihar.contactNumber.isNotEmpty) 'contact_number': vihar.contactNumber,
      'selected_date': DateFormat('yyyy-MM-dd').format(vihar.startDate),
      'ms_name_en': vihar.mahatmaName,
      'is_active': vihar.active,
    };

    final newViharId = await client.create(
      model: 'ai.add.vihar',
      values: viharVals,
    );

    // 2. Create routes for this vihar if provided
    final routesToCreate = vihar.routes.isNotEmpty
        ? vihar.routes
        : (vihar.startLocation.isNotEmpty || vihar.endLocation.isNotEmpty
            ? [
                ViharRoute(
                  id: '0',
                  viharDate: vihar.startDate,
                  fromLocation: vihar.startLocation,
                  toLocation: vihar.endLocation,
                  district: 'Ahmedabad',
                  districtInchargeInfo: '',
                  status: 'Active',
                )
              ]
            : <ViharRoute>[]);

    for (var r in routesToCreate) {
      final fromVillageId = await _findOrCreateVillage(client, r.fromLocation, r.district);
      final toVillageId = await _findOrCreateVillage(client, r.toLocation, r.district);

      final routeVals = <String, dynamic>{
        'vihar_id': newViharId,
        'vihar_date_time': DateFormat('yyyy-MM-dd HH:mm:ss').format(r.viharDate.toUtc()),
        if (fromVillageId != null) 'from_location_id': fromVillageId,
        if (toVillageId != null) 'to_location_id': toVillageId,
        'name_en': '${r.fromLocation} to ${r.toLocation}',
        'name_gu': '${r.fromLocation} to ${r.toLocation}',
        'name_hi': '${r.fromLocation} to ${r.toLocation}',
        'is_active': true,
      };

      await client.create(
        model: 'ai.vihar.route',
        values: routeVals,
      );
    }
  }

  @override
  Future<void> updateVihar(Vihar vihar) async {
    final intId = int.tryParse(vihar.id);
    if (intId == null) return;

    final mId = int.tryParse(vihar.mahatmaId);
    final values = <String, dynamic>{
      if (mId != null) 'code': mId,
      if (vihar.letterNo.isNotEmpty) 'letter_no': vihar.letterNo,
      if (vihar.thanaNo.isNotEmpty) 'thana_no': vihar.thanaNo,
      if (vihar.sevakName.isNotEmpty) 'sevak_name': vihar.sevakName,
      if (vihar.contactNumber.isNotEmpty) 'contact_number': vihar.contactNumber,
      'selected_date': DateFormat('yyyy-MM-dd').format(vihar.startDate),
      if (vihar.mahatmaName.isNotEmpty) 'ms_name_en': vihar.mahatmaName,
      'is_active': vihar.active,
    };

    await client.write(
      model: 'ai.add.vihar',
      id: intId,
      values: values,
    );

    // Sync is_active to all existing routes for this vihar
    try {
      final existingRoutes = await client.searchRead(
        model: 'ai.vihar.route',
        domain: [
          ['vihar_id', '=', intId]
        ],
        fields: ['id'],
        context: {'active_test': false},
      );
      for (var er in existingRoutes) {
        final erId = er['id'] is int ? er['id'] as int : int.tryParse('${er['id']}');
        if (erId != null) {
          try {
            await client.write(
              model: 'ai.vihar.route',
              id: erId,
              values: {'is_active': vihar.active},
            );
          } catch (_) {}
        }
      }
    } catch (_) {}

    // Sync routes for this vihar if provided
    final routesToSync = vihar.routes.isNotEmpty
        ? vihar.routes
        : (vihar.startLocation.isNotEmpty || vihar.endLocation.isNotEmpty
            ? [
                ViharRoute(
                  id: '0',
                  viharDate: vihar.startDate,
                  fromLocation: vihar.startLocation,
                  toLocation: vihar.endLocation,
                  district: 'Ahmedabad',
                  districtInchargeInfo: '',
                  status: vihar.active ? 'Active' : 'Upcoming',
                )
              ]
            : <ViharRoute>[]);

    if (routesToSync.isNotEmpty) {
      final existingRoutes = await client.searchRead(
        model: 'ai.vihar.route',
        domain: [
          ['vihar_id', '=', intId]
        ],
        fields: ['id'],
        context: {'active_test': false},
      );

      final r = routesToSync.first;
      final fromVillageId = await _findOrCreateVillage(client, r.fromLocation, r.district);
      final toVillageId = await _findOrCreateVillage(client, r.toLocation, r.district);

      final routeVals = <String, dynamic>{
        'vihar_id': intId,
        'vihar_date_time': DateFormat('yyyy-MM-dd HH:mm:ss').format(r.viharDate.toUtc()),
        if (fromVillageId != null) 'from_location_id': fromVillageId,
        if (toVillageId != null) 'to_location_id': toVillageId,
        'name_en': '${r.fromLocation} to ${r.toLocation}',
        'name_gu': '${r.fromLocation} to ${r.toLocation}',
        'name_hi': '${r.fromLocation} to ${r.toLocation}',
        'is_active': vihar.active,
      };

      if (existingRoutes.isNotEmpty) {
        final existingId = existingRoutes.first['id'] as int;
        await client.write(
          model: 'ai.vihar.route',
          id: existingId,
          values: routeVals,
        );
      } else {
        await client.create(
          model: 'ai.vihar.route',
          values: routeVals,
        );
      }
    }
  }

  @override
  Future<void> deleteVihar(String id) async {
    final intId = int.tryParse(id);
    if (intId != null) {
      // 1. Delete associated routes first from ai.vihar.route
      try {
        final relatedRoutes = await client.searchRead(
          model: 'ai.vihar.route',
          domain: [
            ['vihar_id', '=', intId]
          ],
          fields: ['id'],
          context: {'active_test': false},
        );
        for (var r in relatedRoutes) {
          final rId = r['id'];
          if (rId is int) {
            try {
              await client.unlink(model: 'ai.vihar.route', id: rId);
            } catch (e) {
              debugPrint('Error unlinking route $rId: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('Error searching routes for vihar $intId deletion: $e');
      }

      // 2. Hard delete the vihar record itself from ai.add.vihar
      try {
        await client.unlink(model: 'ai.add.vihar', id: intId);
      } catch (e) {
        debugPrint('Error unlinking vihar $intId: $e');
        // Fallback: if delete is restricted by foreign key, deactivate
        try {
          await client.write(model: 'ai.add.vihar', id: intId, values: {'is_active': false});
        } catch (_) {}
      }
    }
  }
}

class OdooViharRouteRepository implements ViharRouteRepository {
  final OdooClient client;

  OdooViharRouteRepository(this.client);

  @override
  Future<List<ViharRoute>> getViharRoutes() async {
    final records = await client.searchRead(
      model: 'ai.vihar.route',
      fields: [
        'id',
        'vihar_id',
        'vihar_date_time',
        'from_location_id',
        'to_location_id',
        'name_en',
        'name_gu',
        'name_hi',
        'district_id',
        'district_incharge_info_en',
        'is_active',
        'active',
      ],
      order: 'vihar_date_time desc',
      context: {'active_test': false},
    );

    return records.map((r) {
      String fromLoc = '';
      if (r['from_location_id'] is List && (r['from_location_id'] as List).length > 1) {
        fromLoc = (r['from_location_id'] as List)[1].toString();
        if (fromLoc.contains(' | ')) {
          fromLoc = fromLoc.split(' | ').first.trim();
        }
      }

      String toLoc = '';
      if (r['to_location_id'] is List && (r['to_location_id'] as List).length > 1) {
        toLoc = (r['to_location_id'] as List)[1].toString();
        if (toLoc.contains(' | ')) {
          toLoc = toLoc.split(' | ').first.trim();
        }
      }

      if (fromLoc.isEmpty || toLoc.isEmpty) {
        final rawName = r['name_en'] ?? r['name_gu'] ?? r['name_hi'];
        if (rawName != null && rawName.toString().isNotEmpty) {
          final str = rawName.toString();
          if (str.toLowerCase().contains(' to ')) {
            final parts = str.split(RegExp(r'\s+to\s+', caseSensitive: false));
            if (parts.isNotEmpty && fromLoc.isEmpty) fromLoc = parts.first.trim();
            if (parts.length > 1 && toLoc.isEmpty) toLoc = parts.last.trim();
          } else if (fromLoc.isEmpty && toLoc.isEmpty) {
            fromLoc = str.trim();
            toLoc = str.trim();
          }
        }
      }

      String districtName = '';
      if (r['district_id'] is List && (r['district_id'] as List).length > 1) {
        districtName = (r['district_id'] as List)[1].toString();
      }
      if (districtName.isEmpty && r['from_location_id'] is List && (r['from_location_id'] as List).length > 1) {
        final locFull = (r['from_location_id'] as List)[1].toString();
        if (locFull.contains(' | ')) {
          districtName = locFull.split(' | ').last.trim();
        }
      }
      if (districtName.isEmpty && r['to_location_id'] is List && (r['to_location_id'] as List).length > 1) {
        final locFull = (r['to_location_id'] as List)[1].toString();
        if (locFull.contains(' | ')) {
          districtName = locFull.split(' | ').last.trim();
        }
      }
      if (districtName.isEmpty) districtName = 'Gujarat';

      String inchargeInfo = r['district_incharge_info_en']?.toString() ?? '';

      String vId = '';
      String vName = '';
      if (r['vihar_id'] is List && (r['vihar_id'] as List).isNotEmpty) {
        vId = '${(r['vihar_id'] as List)[0]}';
        if ((r['vihar_id'] as List).length > 1) {
          vName = (r['vihar_id'] as List)[1].toString();
        }
      } else if (r['vihar_id'] is int) {
        vId = '${r['vihar_id']}';
      }

      return ViharRoute(
        id: '${r['id']}',
        viharId: vId,
        viharName: vName,
        viharDate: DateTime.tryParse(r['vihar_date_time']?.toString() ?? '') ?? DateTime.now(),
        fromLocation: fromLoc,
        toLocation: toLoc,
        district: districtName,
        districtInchargeInfo: inchargeInfo,
        distanceKm: 0.0,
        status: (r['is_active'] == true || r['active'] == true) ? 'Active' : 'Upcoming',
      );
    }).toList();
  }

  @override
  Future<ViharRoute?> getViharRouteById(String id) async {
    final list = await getViharRoutes();
    try {
      return list.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addViharRoute(ViharRoute route) async {
    final fromId = await _findOrCreateVillage(client, route.fromLocation, route.district);
    final toId = await _findOrCreateVillage(client, route.toLocation, route.district);
    final intVId = int.tryParse(route.viharId);

    await client.create(
      model: 'ai.vihar.route',
      values: {
        'vihar_date_time': DateFormat('yyyy-MM-dd HH:mm:ss').format(route.viharDate.toUtc()),
        if (fromId != null) 'from_location_id': fromId,
        if (toId != null) 'to_location_id': toId,
        if (intVId != null) 'vihar_id': intVId,
        'name_en': '${route.fromLocation} to ${route.toLocation}',
        'name_gu': '${route.fromLocation} to ${route.toLocation}',
        'name_hi': '${route.fromLocation} to ${route.toLocation}',
        'is_active': route.status == 'Active',
      },
    );
  }

  @override
  Future<void> updateViharRoute(ViharRoute route) async {
    final intId = int.tryParse(route.id);
    if (intId != null) {
      final fromId = await _findOrCreateVillage(client, route.fromLocation, route.district);
      final toId = await _findOrCreateVillage(client, route.toLocation, route.district);
      final intVId = int.tryParse(route.viharId);

      await client.write(
        model: 'ai.vihar.route',
        id: intId,
        values: {
          'vihar_date_time': DateFormat('yyyy-MM-dd HH:mm:ss').format(route.viharDate.toUtc()),
          if (fromId != null) 'from_location_id': fromId,
          if (toId != null) 'to_location_id': toId,
          if (intVId != null) 'vihar_id': intVId,
          'name_en': '${route.fromLocation} to ${route.toLocation}',
          'is_active': route.status == 'Active',
        },
      );
    }
  }

  @override
  Future<void> deleteViharRoute(String id) async {
    final intId = int.tryParse(id);
    if (intId != null) {
      await client.unlink(model: 'ai.vihar.route', id: intId);
    }
  }
}

class OdooSamudayRepository implements SamudayRepository {
  final OdooClient client;
  OdooSamudayRepository(this.client);

  @override
  Future<List<Samuday>> getSamudays() async {
    final records = await client.searchRead(
      model: 'ai.samuday',
      fields: ['id', 'name', 'status'],
      order: 'name asc',
    );
    return records
        .map((r) => Samuday(
              id: '${r['id']}',
              name: r['name']?.toString() ?? '',
              code: 'SAM-${r['id']}',
              status: r['status']?.toString() ?? 'active',
              active: r['status'] == 'active',
            ))
        .toList();
  }

  @override
  Future<void> addSamuday(Samuday item) async =>
      client.create(model: 'ai.samuday', values: {
        'name': item.name.trim(),
        'status': item.status,
      });

  @override
  Future<void> updateSamuday(Samuday item) async {
    final id = int.tryParse(item.id);
    if (id != null) {
      client.write(model: 'ai.samuday', id: id, values: {
        'name': item.name.trim(),
        'status': item.status,
      });
    }
  }

  @override
  Future<void> deleteSamuday(String id) async {
    final intId = int.tryParse(id);
    if (intId != null) client.unlink(model: 'ai.samuday', id: intId);
  }
}

class OdooDistrictRepository implements DistrictRepository {
  final OdooClient client;
  OdooDistrictRepository(this.client);

  @override
  Future<List<District>> getDistricts() async {
    final records = await client.searchRead(
      model: 'ai.district',
      fields: ['id', 'name_en', 'name_gu', 'name_hi', 'name', 'district_id', 'state_id', 'status'],
      order: 'name_en asc',
    );
    return records.map((r) {
      String inchargeId = '';
      String inchargeName = '';
      if (r['district_id'] is List && (r['district_id'] as List).isNotEmpty) {
        inchargeId = '${(r['district_id'] as List)[0]}';
        if ((r['district_id'] as List).length > 1) {
          inchargeName = (r['district_id'] as List)[1].toString();
        }
      }

      String stateId = '';
      String stateName = 'Gujarat';
      if (r['state_id'] is List && (r['state_id'] as List).isNotEmpty) {
        stateId = '${(r['state_id'] as List)[0]}';
        if ((r['state_id'] as List).length > 1) {
          stateName = (r['state_id'] as List)[1].toString();
        }
      }

      final nameEn = r['name_en']?.toString() ?? '';
      final nameGu = r['name_gu']?.toString() ?? '';
      final nameHi = r['name_hi']?.toString() ?? '';
      final name = nameEn.isNotEmpty ? nameEn : (r['name']?.toString() ?? '');

      return District(
        id: '${r['id']}',
        name: name,
        nameEnglish: nameEn,
        nameGujarati: nameGu,
        nameHindi: nameHi,
        inchargeId: inchargeId,
        inchargeName: inchargeName,
        stateId: stateId,
        state: stateName,
        status: r['status']?.toString() ?? 'active',
        active: r['status'] == 'active',
      );
    }).toList();
  }

  @override
  Future<void> addDistrict(District item) async {
    final values = <String, dynamic>{
      'name_en': item.nameEnglish.isNotEmpty ? item.nameEnglish.trim() : item.name.trim(),
      if (item.nameGujarati.isNotEmpty) 'name_gu': item.nameGujarati.trim(),
      if (item.nameHindi.isNotEmpty) 'name_hi': item.nameHindi.trim(),
      'status': item.status,
    };
    final incId = int.tryParse(item.inchargeId);
    if (incId != null) values['district_id'] = incId;
    final stId = int.tryParse(item.stateId);
    if (stId != null) values['state_id'] = stId;

    await client.create(model: 'ai.district', values: values);
  }

  @override
  Future<void> updateDistrict(District item) async {
    final id = int.tryParse(item.id);
    if (id != null) {
      final values = <String, dynamic>{
        'name_en': item.nameEnglish.isNotEmpty ? item.nameEnglish.trim() : item.name.trim(),
        'name_gu': item.nameGujarati.trim(),
        'name_hi': item.nameHindi.trim(),
        'status': item.status,
      };
      final incId = int.tryParse(item.inchargeId);
      if (incId != null) values['district_id'] = incId;
      final stId = int.tryParse(item.stateId);
      if (stId != null) values['state_id'] = stId;

      await client.write(model: 'ai.district', id: id, values: values);
    }
  }

  @override
  Future<void> deleteDistrict(String id) async {
    final intId = int.tryParse(id);
    if (intId != null) client.unlink(model: 'ai.district', id: intId);
  }
}

class OdooDistrictInchargeRepository implements DistrictInchargeRepository {
  final OdooClient client;
  OdooDistrictInchargeRepository(this.client);

  @override
  Future<List<DistrictIncharge>> getDistrictIncharges() async {
    final records = await client.searchRead(
      model: 'ai.district.incharge',
      fields: ['id', 'display_name', 'first_name', 'last_name', 'phone', 'email', 'stage'],
      order: 'id desc',
    );
    return records.map((r) {
      final fn = r['first_name']?.toString() ?? '';
      final ln = r['last_name']?.toString() ?? '';
      String name = r['display_name']?.toString() ?? '';
      if (name.isEmpty) {
        name = '$fn $ln'.trim();
      }
      return DistrictIncharge(
        id: '${r['id']}',
        firstName: fn,
        lastName: ln,
        name: name.isNotEmpty ? name : 'Incharge #${r['id']}',
        district: 'Gujarat',
        phone: r['phone']?.toString() ?? '',
        contactNumber: r['phone']?.toString() ?? '',
        email: r['email']?.toString() ?? '',
        stage: r['stage']?.toString() ?? 'active',
        active: r['stage'] != 'inactive',
      );
    }).toList();
  }

  @override
  Future<void> addDistrictIncharge(DistrictIncharge item) async {
    await client.create(
      model: 'ai.district.incharge',
      values: {
        'first_name': item.firstName.isNotEmpty ? item.firstName.trim() : item.name.trim(),
        'last_name': item.lastName.trim(),
        'phone': item.phone.isNotEmpty ? item.phone.trim() : item.contactNumber.trim(),
        'email': item.email.trim(),
        if (item.password.isNotEmpty) 'password': item.password,
        'stage': item.stage,
      },
    );
  }

  @override
  Future<void> updateDistrictIncharge(DistrictIncharge item) async {
    final id = int.tryParse(item.id);
    if (id != null) {
      await client.write(
        model: 'ai.district.incharge',
        id: id,
        values: {
          'first_name': item.firstName.isNotEmpty ? item.firstName.trim() : item.name.trim(),
          'last_name': item.lastName.trim(),
          'phone': item.phone.isNotEmpty ? item.phone.trim() : item.contactNumber.trim(),
          'email': item.email.trim(),
          if (item.password.isNotEmpty) 'password': item.password,
          'stage': item.stage,
        },
      );
    }
  }

  @override
  Future<void> deleteDistrictIncharge(String id) async {
    final intId = int.tryParse(id);
    if (intId != null) client.unlink(model: 'ai.district.incharge', id: intId);
  }
}

class OdooStateRepository implements StateRepository {
  final OdooClient client;
  OdooStateRepository(this.client);

  @override
  Future<List<StateModel>> getStates() async {
    final records = await client.searchRead(
      model: 'ai.state',
      fields: ['id', 'name_en', 'name_gu', 'name_hi', 'name', 'status'],
      order: 'name_en asc',
    );
    return records.map((r) {
      final nameEn = r['name_en']?.toString() ?? '';
      final nameGu = r['name_gu']?.toString() ?? '';
      final nameHi = r['name_hi']?.toString() ?? '';
      final name = nameEn.isNotEmpty ? nameEn : (r['name']?.toString() ?? 'State');
      return StateModel(
        id: '${r['id']}',
        name: name,
        nameEnglish: nameEn,
        nameGujarati: nameGu,
        nameHindi: nameHi,
        code: 'ST-${r['id']}',
        country: 'India',
        status: r['status']?.toString() ?? 'active',
        active: r['status'] == 'active',
      );
    }).toList();
  }

  @override
  Future<void> addState(StateModel item) async =>
      client.create(model: 'ai.state', values: {
        'name_en': item.nameEnglish.isNotEmpty ? item.nameEnglish.trim() : item.name.trim(),
        if (item.nameGujarati.isNotEmpty) 'name_gu': item.nameGujarati.trim(),
        if (item.nameHindi.isNotEmpty) 'name_hi': item.nameHindi.trim(),
        'status': item.status,
      });

  @override
  Future<void> updateState(StateModel item) async {
    final id = int.tryParse(item.id);
    if (id != null) {
      client.write(model: 'ai.state', id: id, values: {
        'name_en': item.nameEnglish.isNotEmpty ? item.nameEnglish.trim() : item.name.trim(),
        'name_gu': item.nameGujarati.trim(),
        'name_hi': item.nameHindi.trim(),
        'status': item.status,
      });
    }
  }

  @override
  Future<void> deleteState(String id) async {
    final intId = int.tryParse(id);
    if (intId != null) client.unlink(model: 'ai.state', id: intId);
  }
}

class OdooSalutationRepository implements SalutationRepository {
  final OdooClient client;
  OdooSalutationRepository(this.client);

  @override
  Future<List<Salutation>> getSalutations() async {
    final records = await client.searchRead(
      model: 'ai.salutation',
      fields: [
        'id',
        'name_en',
        'name_gu',
        'name_hi',
        'name',
        'salutation_prefix',
        'status',
        'group_id',
        'group_type',
        'district_id',
        'state_id'
      ],
      order: 'id asc',
    );
    return records.map((r) {
      String gId = '';
      String gName = '';
      if (r['group_id'] is List && (r['group_id'] as List).isNotEmpty) {
        gId = '${(r['group_id'] as List)[0]}';
        if ((r['group_id'] as List).length > 1) {
          gName = (r['group_id'] as List)[1].toString();
        }
      }

      String distId = '';
      String distName = '';
      if (r['district_id'] is List && (r['district_id'] as List).isNotEmpty) {
        distId = '${(r['district_id'] as List)[0]}';
        if ((r['district_id'] as List).length > 1) {
          distName = (r['district_id'] as List)[1].toString();
        }
      }

      String stId = '';
      String stName = '';
      if (r['state_id'] is List && (r['state_id'] as List).isNotEmpty) {
        stId = '${(r['state_id'] as List)[0]}';
        if ((r['state_id'] as List).length > 1) {
          stName = (r['state_id'] as List)[1].toString();
        }
      }

      final nameEn = r['name_en']?.toString() ?? '';
      final nameGu = r['name_gu']?.toString() ?? '';
      final nameHi = r['name_hi']?.toString() ?? '';
      final prefix = r['salutation_prefix']?.toString() ?? '';
      final title = nameEn.isNotEmpty ? nameEn : (prefix.isNotEmpty ? prefix.toUpperCase() : 'Shri');

      return Salutation(
        id: '${r['id']}',
        title: title,
        nameEnglish: nameEn,
        nameGujarati: nameGu,
        nameHindi: nameHi,
        salutationPrefix: prefix,
        groupId: gId,
        groupName: gName,
        districtId: distId,
        districtName: distName,
        stateId: stId,
        stateName: stName,
        groupType: r['group_type']?.toString() ?? '',
        status: r['status']?.toString() ?? 'active',
        active: r['status'] == 'active',
      );
    }).toList();
  }

  @override
  Future<void> addSalutation(Salutation item) async {
    final values = <String, dynamic>{
      if (item.nameEnglish.isNotEmpty) 'name_en': item.nameEnglish.trim(),
      if (item.nameGujarati.isNotEmpty) 'name_gu': item.nameGujarati.trim(),
      if (item.nameHindi.isNotEmpty) 'name_hi': item.nameHindi.trim(),
      'status': item.status,
      if (item.salutationPrefix.isNotEmpty) 'salutation_prefix': item.salutationPrefix.toLowerCase(),
    };
    final gId = int.tryParse(item.groupId);
    if (gId != null) values['group_id'] = gId;
    await client.create(model: 'ai.salutation', values: values);
  }

  @override
  Future<void> updateSalutation(Salutation item) async {
    final id = int.tryParse(item.id);
    if (id != null) {
      final values = <String, dynamic>{
        if (item.nameEnglish.isNotEmpty) 'name_en': item.nameEnglish.trim(),
        if (item.nameGujarati.isNotEmpty) 'name_gu': item.nameGujarati.trim(),
        if (item.nameHindi.isNotEmpty) 'name_hi': item.nameHindi.trim(),
        'status': item.status,
        if (item.salutationPrefix.isNotEmpty) 'salutation_prefix': item.salutationPrefix.toLowerCase(),
      };
      final gId = int.tryParse(item.groupId);
      if (gId != null) values['group_id'] = gId;
      await client.write(model: 'ai.salutation', id: id, values: values);
    }
  }

  @override
  Future<void> deleteSalutation(String id) async {
    final intId = int.tryParse(id);
    if (intId != null) client.unlink(model: 'ai.salutation', id: intId);
  }
}

class OdooUserRepository implements UserRepository {
  final OdooClient client;
  OdooUserRepository(this.client);

  @override
  Future<List<UserModel>> getUsers() async {
    try {
      final records = await client.searchRead(
        model: 'res.users',
        fields: ['id', 'name', 'login', 'email', 'active'],
        order: 'name asc',
      );
      return records.map((r) => UserModel(
        id: '${r['id']}',
        username: r['login']?.toString() ?? '',
        fullName: r['name']?.toString() ?? '',
        role: 'Administrator',
        email: r['email']?.toString() ?? '',
        status: (r['active'] == true) ? 'Active' : 'Inactive',
      )).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> addUser(UserModel user) async {}
  @override
  Future<void> updateUser(UserModel user) async {}
  @override
  Future<void> deleteUser(String id) async {}
}

class OdooVillageRepository implements VillageRepository {
  final OdooClient client;
  OdooVillageRepository(this.client);

  @override
  Future<List<Village>> getVillages() async {
    try {
      final List<Map<String, dynamic>> allRecords = [];
      const int batchSize = 500;
      int offset = 0;
      bool hasMore = true;

      while (hasMore) {
        List<Map<String, dynamic>> batch = [];
        try {
          batch = await client.searchRead(
            model: 'ai.village',
            fields: ['id', 'name_en', 'name_gu', 'name_hi', 'name', 'district_id', 'status'],
            limit: batchSize,
            offset: offset,
            order: 'name_en asc, id asc',
          );
        } catch (e1) {
          debugPrint('[OdooVillageRepository] First batch searchRead failed: $e1. Retrying with basic fields...');
          try {
            batch = await client.searchRead(
              model: 'ai.village',
              fields: ['id', 'name_en', 'name', 'district_id', 'status'],
              limit: batchSize,
              offset: offset,
              order: 'id asc',
            );
          } catch (e2) {
            debugPrint('[OdooVillageRepository] Fallback batch searchRead failed: $e2');
            batch = await client.searchRead(
              model: 'ai.village',
              fields: ['id', 'name', 'district_id'],
              limit: batchSize,
              offset: offset,
            );
          }
        }

        if (batch.isEmpty) {
          hasMore = false;
        } else {
          allRecords.addAll(batch);
          offset += batch.length;
          if (batch.length < batchSize) {
            hasMore = false;
          }
        }
      }

      return allRecords.map((r) {
        String districtId = '';
        String districtName = '';
        if (r['district_id'] is List && (r['district_id'] as List).isNotEmpty) {
          districtId = '${(r['district_id'] as List)[0]}';
          if ((r['district_id'] as List).length > 1) {
            districtName = (r['district_id'] as List)[1].toString();
          }
        }

        final rawName = r['name']?.toString() ?? '';
        final parts = rawName.split('|').map((p) => p.trim()).toList();

        // 1. English Name
        String nameEn = r['name_en']?.toString().trim() ?? '';
        if (nameEn.isEmpty && parts.isNotEmpty) {
          nameEn = parts[0].replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
        }

        // 2. Gujarati Name
        String nameGu = r['name_gu']?.toString().trim() ?? '';
        if (nameGu.isEmpty && parts.length > 1) {
          nameGu = parts[1].replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
        }

        // 3. Hindi Name
        String nameHi = r['name_hi']?.toString().trim() ?? '';
        if (nameHi.isEmpty && parts.length > 2) {
          nameHi = parts[2].replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
        }

        // 4. District fallback from rawName if district_id was unassigned
        if (districtName.isEmpty) {
          final distMatch = RegExp(r'\(([^)]+)\)').firstMatch(rawName);
          if (distMatch != null && distMatch.groupCount >= 1) {
            districtName = distMatch.group(1)!.trim();
          }
        }

        final displayName = nameEn.isNotEmpty
            ? nameEn
            : (parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : (rawName.isNotEmpty ? rawName : 'Village #${r['id']}'));

        final rawStatus = r['status'];
        final status = (rawStatus == 'inactive' || rawStatus == 'Inactive') ? 'inactive' : 'active';

        return Village(
          id: '${r['id']}',
          name: displayName,
          nameEnglish: nameEn.isNotEmpty ? nameEn : displayName,
          nameGujarati: nameGu,
          nameHindi: nameHi,
          districtId: districtId,
          districtName: districtName,
          status: status,
          active: status == 'active',
        );
      }).toList();
    } catch (e) {
      debugPrint('[OdooVillageRepository] getVillages error: $e');
      return [];
    }
  }

  @override
  Future<void> addVillage(Village item) async {
    final values = <String, dynamic>{
      'name_en': item.nameEnglish.isNotEmpty ? item.nameEnglish.trim() : item.name.trim(),
      if (item.nameGujarati.isNotEmpty) 'name_gu': item.nameGujarati.trim(),
      if (item.nameHindi.isNotEmpty) 'name_hi': item.nameHindi.trim(),
      'status': item.status,
    };
    final dId = int.tryParse(item.districtId);
    if (dId != null) {
      values['district_id'] = dId;
    }
    await client.create(model: 'ai.village', values: values);
  }

  @override
  Future<void> updateVillage(Village item) async {
    final id = int.tryParse(item.id);
    if (id != null) {
      final values = <String, dynamic>{
        'name_en': item.nameEnglish.isNotEmpty ? item.nameEnglish.trim() : item.name.trim(),
        'name_gu': item.nameGujarati.trim(),
        'name_hi': item.nameHindi.trim(),
        'status': item.status,
      };
      final dId = int.tryParse(item.districtId);
      if (dId != null) {
        values['district_id'] = dId;
      }
      await client.write(model: 'ai.village', id: id, values: values);
    }
  }

  @override
  Future<void> deleteVillage(String id) async {
    final intId = int.tryParse(id);
    if (intId != null) {
      try {
        await client.write(model: 'ai.village', id: intId, values: {'status': 'inactive'});
      } catch (_) {
        await client.unlink(model: 'ai.village', id: intId);
      }
    }
  }
}

