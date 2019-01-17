import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firestore_helpers/firestore_helpers.dart';
import 'package:jam_dart_interfaces/interfaces.dart';
import 'package:jam_dart_models/models.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

class DatabaseService implements DatabaseInterface {
  @override
  List<Table> tables;

  final firestore.Firestore _firestore = firestore.Firestore.instance;

  DatabaseService() {
    this._firestore.settings(timestampsInSnapshotsEnabled: true);
  }

  Future<bool> initialize() async {
    firestore.QuerySnapshot snapshot =
        await this._firestore.collection('/Metadata').snapshots().first;
    this.tables = snapshot.documents
        .map((document) => Table.fromMap(key: document.documentID, map: document.data))
        .toList();
    return true;
  }

  T _mapToModel<T extends Data>(firestore.DocumentSnapshot document, Table<T> table) {
    return table.modelCreator(key: document.documentID, map: document.data);
  }

  List<T> _mapToModels<T extends Data>(List<firestore.DocumentSnapshot> documents, Table<T> table) {
    return documents
        .map((document) => table.modelCreator(key: document.documentID, map: document.data))
        .toList();
  }

  bool _isValidPath(String path) {
    return (path != null && path.indexOf('{') < 0);
  }

  firestore.CollectionReference _getCollection<T extends Data>(Table<T> table) {
    return this._isValidPath(table.resolvedPath)
        ? this._firestore.collection(table.resolvedPath)
        : null;
  }

  @override
  Observable<String> add<T extends Data>(Table<T> table, {T item}) {
    // TODO: implement add
    return null;
  }

  @override
  Observable<List<String>> addMany<T extends Data>(Table<T> table, {List<T> items}) {
    // TODO: implement addMany
    return null;
  }

  @override
  Observable<bool> clone<S extends Data, T extends Data>(
      {Table<S> sourceTable, Table<T> targetTable, bool replace = false}) {
    // TODO: implement clone
    return null;
  }

  @override
  Observable<bool> exists<T extends Data>(Table<T> table, {String key}) {
    // TODO: implement exists
    return null;
  }

  @override
  Observable<List<T>> where<T extends Data>(Table<T> table,
      {String searchColumn, String operator, searchKey}) {
    // TODO: implement filter
    return null;
  }

  @override
  Observable<List<T>> filter<T extends Data>(Table<T> table,
      {String searchColumn, String operator, searchKey}) {
    return this.where(table, searchColumn: searchColumn, searchKey: searchKey);
  }

  @override
  Observable<T> find<T extends Data>(Table<T> table, {String searchColumn, searchKey}) {
    // TODO: implement find
    return null;
  }

  @override
  Observable<List<T>> findAround<T extends Data>(
    Table<T> table, {
    @required GeoPoint center,
    @required double radiusInKm,
    @required String locationFieldNameInDB,
  }) {
    final collection = this._getCollection<T>(table);
    if (collection == null) return Observable.just(null);

    return Observable(getDataInArea<T>(
      source: collection,
      area: Area(firestore.GeoPoint(center.latitude, center.longitude), radiusInKm),
      locationFieldNameInDB: locationFieldNameInDB,
      mapper: (document) => this._mapToModel(document, table),
    ));
  }

  @override
  Observable<List<T>> findMany<T extends Data>(Table<T> table,
      {String searchColumn, List<String> searchKeys}) {
    // TODO: implement findMany
    return null;
  }

  @override
  Observable<T> forceLookup<T extends Data>(Table<T> table,
      {T item, String searchColumn, searchKey}) {
    // TODO: implement forceLookup
    return null;
  }

  @override
  Observable<T> get<T extends Data>(Table<T> table, {String key}) {
    final collection = this._getCollection(table);
    if (key == null || collection == null) return Observable.just(null);

    return collection
        .document(key)
        .snapshots()
        .map((document) => this._mapToModel(document, table));
  }

  @override
  Observable<List<T>> getMany<T extends Data>(Table<T> table, {List<String> keys}) {
    // TODO: implement getMany
    return null;
  }

  @override
  Observable<List<T>> list<T extends Data>(Table<T> table) {
    final collection = this._getCollection<T>(table);
    if (collection == null) return Observable.just(null);

    return collection.snapshots().map((snapshot) => this._mapToModels(snapshot.documents, table));
  }

  @override
  Observable<List<T>> listFirst<T extends Data>(Table<T> table, {int limit}) {
    // TODO: implement listFirst
    return null;
  }

  @override
  Observable<T> lookup<T extends Data>(Table<T> table, {String searchColumn, searchKey}) {
    // TODO: implement lookup
    return null;
  }

  @override
  Observable<String> modify<T extends Data>(Table<T> table,
      {T item, String searchColumn, searchKey}) {
    // TODO: implement modify
    return null;
  }

  @override
  Observable<String> modifyElseAdd<T extends Data>(Table<T> table,
      {T item, String searchColumn, searchKey}) {
    // TODO: implement modifyElseAdd
    return null;
  }

  @override
  Observable<String> modifyFields<T extends Data>(Table<T> table,
      {T item, String searchColumn, searchKey}) {
    // TODO: implement modifyFields
    return null;
  }

  @override
  Observable<String> modifyFieldsMany<T extends Data>(Table<T> table,
      {List<T> items, String searchColumn, searchKey}) {
    // TODO: implement modifyFieldsMany
    return null;
  }

  @override
  Observable<T> remove<T extends Data>(Table<T> table, {String key}) {
    // TODO: implement remove
    return null;
  }

  @override
  Observable<T> removeMany<T extends Data>(Table<T> table, {List<String> keys}) {
    // TODO: implement removeMany
    return null;
  }
}
