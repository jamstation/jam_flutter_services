import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firestore_helpers/firestore_helpers.dart';
import 'package:jam_dart_interfaces/interfaces.dart';
import 'package:jam_dart_models/models.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

class DatabaseService implements DatabaseInterface {
  @override
  Map<String, Table<dynamic>> get tables => _tables;
  final firestore.Firestore _firestore = firestore.Firestore.instance
    ..settings(
      timestampsInSnapshotsEnabled: true,
      persistenceEnabled: false,
    );
  Map<String, Table<dynamic>> _tables;

  DatabaseService() {
    // this._firestore.settings(
    //       timestampsInSnapshotsEnabled: true,
    //       persistenceEnabled: false,
    //     );
  }

  @override
  Future<bool> initialize({
    String metadataPath,
    @required
        Map<String, Table<dynamic> Function(Table<dynamic>)> instanceCreators,
  }) async {
    metadataPath = metadataPath ?? '/Metadata';
    firestore.QuerySnapshot snapshot =
        await this._firestore.collection(metadataPath).snapshots().first;

    _tables = snapshot.documents
        .map((document) =>
            Table.fromMap(key: document.documentID, map: document.data))
        .toList()
        .asMap()
        .map((key, table) => MapEntry(
              table.name,
              instanceCreators.containsKey(table.name)
                  ? instanceCreators[table.name](table)
                  : table,
            ));
    return true;
  }

  @override
  void resolvePaths(String key, String value) {
    _tables = tables.map((tableKey, table) => MapEntry(
          tableKey,
          table.copyWith(
              resolvedPath: table.path.replaceFirst('{' + key + '}', value)),
        ));
  }

  T _mapToModel<T extends Data>(
    Table<T> table,
    firestore.DocumentSnapshot document,
  ) {
    assert(table != null);
    assert(document != null);

    return table.modelCreator(
      key: document.documentID,
      map: document.data,
    );
  }

  List<T> _mapToModels<T extends Data>(
    Table<T> table,
    List<firestore.DocumentSnapshot> documents,
  ) {
    assert(table != null);
    assert(documents != null);

    return documents
        .map((document) =>
            table.modelCreator(key: document.documentID, map: document.data))
        .toList();
  }

  bool _isValidPath(String path) {
    return (path != null && path.indexOf('{') < 0);
  }

  firestore.CollectionReference _getCollection<T extends Data>(Table<T> table) {
    return this._isValidPath(table?.resolvedPath)
        ? this._firestore.collection(table.resolvedPath)
        : null;
  }

  @override
  Observable<String> add<T extends Data>(
    Table<T> table, {
    @required T item,
  }) {
    assert(item != null);
    final collection = this._getCollection(table);
    assert(collection != null);

    final result = collection.add(item.toMap());

    return Observable.fromFuture(result).map((document) => document.documentID);
  }

  @override
  Observable<List<String>> addMany<T extends Data>(
    Table<T> table, {
    @required List<T> items,
  }) {
    // TODO: implement addMany
    return null;
  }

  @override
  Observable<bool> clone<S extends Data, T extends Data>({
    Table<S> sourceTable,
    Table<T> targetTable,
    bool replace = false,
  }) {
    // TODO: implement clone
    return null;
  }

  @override
  Observable<bool> exists<T extends Data>(
    Table<T> table, {
    String searchColumn,
    String operator,
    dynamic searchKey,
  }) {
    final collection = this._getCollection(table);
    if (searchKey == null || collection == null) return Observable.just(false);

    final result = searchColumn == null
        ? collection.document(searchKey).snapshots()
        : collection.where(searchColumn, isEqualTo: searchKey).snapshots().map(
            (querySnapshot) => querySnapshot.documents.isEmpty
                ? null
                : querySnapshot.documents[0]);

    return Observable(result)
        .map((document) => document == null ? false : document.exists);
  }

  @override
  Observable<List<T>> where<T extends Data>(
    Table<T> table, {
    String searchColumn,
    String operator,
    dynamic searchKey,
  }) {
    // TODO: implement filter
    return null;
  }

  @override
  Observable<List<T>> filter<T extends Data>(
    Table<T> table, {
    @required String searchColumn,
    String operator,
    @required dynamic searchKey,
  }) {
    return this.where(table, searchColumn: searchColumn, searchKey: searchKey);
  }

  @override
  Observable<T> find<T extends Data>(
    Table<T> table, {
    @required String searchColumn,
    @required dynamic searchKey,
  }) {
    assert(searchKey != null);
    assert(searchColumn != null);
    final collection = this._getCollection(table);
    assert(collection != null);

    final result = collection
        .where(searchColumn, isEqualTo: searchKey)
        .snapshots()
        .where((querySnapshot) => querySnapshot.documents.isNotEmpty)
        .map((querySnapshot) => querySnapshot.documents[0]);

    return Observable(result)
        .map((documentSnapshot) => this._mapToModel(table, documentSnapshot));
  }

  @override
  Observable<List<T>> findAround<T extends Data>(
    Table<T> table, {
    @required GeoPoint center,
    @required double radiusInKm,
    @required String locationFieldNameInDB,
  }) {
    assert(center != null);
    assert(radiusInKm != null);
    final collection = this._getCollection(table);
    assert(collection != null);

    final result = getDataInArea<T>(
      source: collection,
      area: Area(
        firestore.GeoPoint(center.latitude, center.longitude),
        radiusInKm,
      ),
      locationFieldNameInDB: locationFieldNameInDB,
      mapper: (document) => this._mapToModel(table, document),
    );

    return Observable(result);
  }

  @override
  Observable<List<T>> findMany<T extends Data>(
    Table<T> table, {
    String searchColumn,
    List<String> searchKeys,
  }) {
    // TODO: implement findMany
    return null;
  }

  @override
  Observable<T> forceGet<T extends Data>(
    Table<T> table, {
    T item,
    String searchColumn,
    dynamic searchKey,
  }) {
    return this
        .exists(table, searchColumn: searchColumn, searchKey: searchKey)
        .switchMap((doesExists) => doesExists
            ? this.find(table, searchColumn: searchColumn, searchKey: searchKey)
            : this.add(table, item: item).switchMap((key) =>
                this.find(table, searchColumn: searchColumn, searchKey: key)));
  }

  @override
  Observable<T> forceLookup<T extends Data>(
    Table<T> table, {
    T item,
    String searchColumn,
    searchKey,
  }) {
    return this
        .lookup(table, searchColumn: searchColumn, searchKey: searchKey)
        .switchMap((lookedupItem) => lookedupItem == null
            ? this
                .add(table, item: item)
                .switchMap((key) => this.lookup(table, searchKey: key))
            : Observable.just(lookedupItem));
  }

  @override
  Observable<T> get<T extends Data>(
    Table<T> table, {
    String key,
  }) {
    assert(key != null);
    final collection = this._getCollection(table);
    assert(collection != null);

    final result = collection.document(key).snapshots();

    return Observable(result)
        .map((document) => this._mapToModel(table, document));
  }

  @override
  Observable<List<T>> getMany<T extends Data>(
    Table<T> table, {
    List<String> keys,
  }) {
    // TODO: implement getMany
    return null;
  }

  @override
  Observable<List<T>> list<T extends Data>(Table<T> table) {
    final collection = this._getCollection(table);
    assert(collection != null);

    final result = collection.snapshots();

    return Observable(result)
        .map((snapshot) => this._mapToModels(table, snapshot.documents));
  }

  @override
  Observable<List<T>> listFirst<T extends Data>(
    Table<T> table, {
    int limit,
  }) {
    // TODO: implement listFirst
    return null;
  }

  @override
  Observable<T> lookup<T extends Data>(
    Table<T> table, {
    String searchColumn,
    searchKey,
  }) {
    assert(searchKey != null);
    final collection = this._getCollection(table);
    assert(collection != null);

    return searchColumn == null
        ? this.get(table, key: searchKey).take(1)
        : this
            .find(table, searchColumn: searchColumn, searchKey: searchKey)
            .take(1);
  }

  @override
  Observable<String> modify<T extends Data>(
    Table<T> table, {
    T item,
    String searchColumn,
    searchKey,
  }) {
    // TODO: implement modify
    return null;
  }

  @override
  Observable<String> modifyElseAdd<T extends Data>(
    Table<T> table, {
    T item,
    String searchColumn,
    searchKey,
  }) {
    // TODO: implement modifyElseAdd
    return null;
  }

  @override
  Observable<String> modifyFields<T extends Data>(
    Table<T> table, {
    T item,
    String searchColumn,
    searchKey,
  }) {
    // TODO: implement modifyFields
    return null;
  }

  @override
  Observable<String> modifyFieldsMany<T extends Data>(
    Table<T> table, {
    List<T> items,
    String searchColumn,
    searchKey,
  }) {
    // TODO: implement modifyFieldsMany
    return null;
  }

  @override
  Observable<T> remove<T extends Data>(
    Table<T> table, {
    String key,
  }) {
    // TODO: implement remove
    return null;
  }

  @override
  Observable<T> removeMany<T extends Data>(
    Table<T> table, {
    List<String> keys,
  }) {
    // TODO: implement removeMany
    return null;
  }
}
