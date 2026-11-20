protocol StoragePort {
    func load<Value: Decodable>(_ type: Value.Type, key: String, version: Int) -> Value?
    func save<Value: Encodable>(_ value: Value, key: String, version: Int)
    func setAside(key: String)
}
