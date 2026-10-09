import Foundation

/// GetIt-style dependency container. No external libraries, matching the pattern
/// used by the Android and Flutter teams.
@MainActor
final class ServiceLocator {
    private enum Registration {
        case factory(() -> Any)
        case lazySingleton(() -> Any)
        case singleton(Any)
    }

    private var registrations: [String: Registration] = [:]

    private func key(_ type: Any.Type, name: String?) -> String {
        let base = String(reflecting: type)
        return name.map { "\(base)#\($0)" } ?? base
    }

    func registerFactory<T>(_ type: T.Type, name: String? = nil, _ factory: @escaping () -> T) {
        registrations[key(type, name: name)] = .factory(factory)
    }

    func registerLazySingleton<T>(_ type: T.Type, name: String? = nil, _ factory: @escaping () -> T) {
        registrations[key(type, name: name)] = .lazySingleton(factory)
    }

    func registerSingleton<T>(_ type: T.Type, name: String? = nil, instance: T) {
        registrations[key(type, name: name)] = .singleton(instance)
    }

    func isRegistered<T>(_ type: T.Type, name: String? = nil) -> Bool {
        registrations[key(type, name: name)] != nil
    }

    func resolve<T>(_ type: T.Type = T.self, name: String? = nil) -> T {
        let k = key(type, name: name)
        guard let registration = registrations[k] else {
            fatalError("No dependency registered for \(k). Check the matching <Feature>Module.")
        }

        switch registration {
        case .factory(let factory):
            guard let value = factory() as? T else {
                fatalError("The factory registered for \(k) does not produce the expected type.")
            }
            return value
        case .lazySingleton(let factory):
            guard let value = factory() as? T else {
                fatalError("The lazy singleton registered for \(k) does not produce the expected type.")
            }
            registrations[k] = .singleton(value)
            return value
        case .singleton(let instance):
            guard let value = instance as? T else {
                fatalError("The instance registered for \(k) does not match the expected type.")
            }
            return value
        }
    }

    func callAsFunction<T>(name: String? = nil) -> T {
        resolve(T.self, name: name)
    }

    func reset() {
        registrations.removeAll()
    }
}

@MainActor let sl = ServiceLocator()
