import '../../models/app_models.dart';

abstract class AuthRepository {
  Future<bool> login(String username, String password);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
}

abstract class MahatmaRepository {
  Future<List<Mahatma>> getMahatmas();
  Future<Mahatma?> getMahatmaById(String id);
  Future<void> addMahatma(Mahatma mahatma);
  Future<void> updateMahatma(Mahatma mahatma);
  Future<void> deleteMahatma(String id);
}

abstract class ViharRepository {
  Future<List<Vihar>> getVihars();
  Future<Vihar?> getViharById(String id);
  Future<void> addVihar(Vihar vihar);
  Future<void> updateVihar(Vihar vihar);
  Future<void> deleteVihar(String id);
}

abstract class ViharRouteRepository {
  Future<List<ViharRoute>> getViharRoutes();
  Future<ViharRoute?> getViharRouteById(String id);
  Future<void> addViharRoute(ViharRoute route);
  Future<void> updateViharRoute(ViharRoute route);
  Future<void> deleteViharRoute(String id);
}

abstract class SamudayRepository {
  Future<List<Samuday>> getSamudays();
  Future<void> addSamuday(Samuday item);
  Future<void> updateSamuday(Samuday item);
  Future<void> deleteSamuday(String id);
}

abstract class DistrictRepository {
  Future<List<District>> getDistricts();
  Future<void> addDistrict(District item);
  Future<void> updateDistrict(District item);
  Future<void> deleteDistrict(String id);
}

abstract class DistrictInchargeRepository {
  Future<List<DistrictIncharge>> getDistrictIncharges();
  Future<void> addDistrictIncharge(DistrictIncharge item);
  Future<void> updateDistrictIncharge(DistrictIncharge item);
  Future<void> deleteDistrictIncharge(String id);
}

abstract class StateRepository {
  Future<List<StateModel>> getStates();
  Future<void> addState(StateModel item);
  Future<void> updateState(StateModel item);
  Future<void> deleteState(String id);
}

abstract class SalutationRepository {
  Future<List<Salutation>> getSalutations();
  Future<void> addSalutation(Salutation item);
  Future<void> updateSalutation(Salutation item);
  Future<void> deleteSalutation(String id);
}

abstract class UserRepository {
  Future<List<UserModel>> getUsers();
  Future<void> addUser(UserModel user);
  Future<void> updateUser(UserModel user);
  Future<void> deleteUser(String id);
}

abstract class VillageRepository {
  Future<List<Village>> getVillages();
  Future<void> addVillage(Village item);
  Future<void> updateVillage(Village item);
  Future<void> deleteVillage(String id);
}

