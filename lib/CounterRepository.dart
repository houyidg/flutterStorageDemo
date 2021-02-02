class CounterRepository implements IRepository {
  IRepository dataSource;

  CounterRepository(this.dataSource);

  @override
  Future<String> get(String key) async {
    var value = await dataSource.get(key);
    return value==null?"0":value;
  }

  @override
  Future<bool> save(String key, String value) {
    return dataSource.save(key,value);
  }
}

abstract class IRepository {
  Future<bool> save(String key, String value);

  Future<String> get(String key);
}
